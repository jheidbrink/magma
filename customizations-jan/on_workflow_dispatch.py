#!/usr/bin/env python3

"""Customize code on my fork programatically.
I hope this is easier to maintain than manually resolving merge conflicts.
"""

import logging
import os
from enum import Enum, auto
from pathlib import Path
import sys
from textwrap import dedent
from typing import cast


class ParserLocation(Enum):
    NORMAL = auto()
    ON_BLOCK = auto()
    WORKFLOW_DISPATCH_BLOCK = auto()

magma_root = Path(os.getenv("MAGMA_ROOT"))
workflows_folder = magma_root / ".github" / "workflows"

def convert_to_workflow_dispatch(workflow_definition: str) -> str:
    """Takes a Github Actions workflow definition, removes all triggers but workflow_dispatch
    and adds workflow_dispatch if it wasn't present
    """
    out_lines: list[str] = []
    parser_location = ParserLocation.NORMAL
    already_contained_workflow_dispatch = False
    for line in workflow_definition.splitlines():
        match parser_location:
            case ParserLocation.NORMAL:
                logging.debug("Appending normal line %s", line)
                out_lines.append(line)
                if line.startswith("on:"):
                    logging.debug("Because of line %s moving to ON_BLOCK", line)
                    parser_location = ParserLocation.ON_BLOCK
            case ParserLocation.ON_BLOCK:
                if not line.startswith("  "):
                    logging.debug("Because of line %s moving to NORMAL", line)
                    parser_location = ParserLocation.NORMAL
                    if not already_contained_workflow_dispatch:
                        logging.debug("We didnt already have workflow_dispatch, adding it")
                        out_lines += ["  workflow_dispatch:"]
                    logging.debug("As we are moving to NORMAL, appending line %s", line)
                    out_lines.append(line)
                if line.startswith("  workflow_dispatch"):
                    logging.debug("Found workflow_dispatch, moving to WORKFLOW_DISPATCH_BLOCK, registering the info and adding line %s", line)
                    parser_location = ParserLocation.WORKFLOW_DISPATCH_BLOCK
                    out_lines.append(line)
                    already_contained_workflow_dispatch = True
            case ParserLocation.WORKFLOW_DISPATCH_BLOCK:
                if line.startswith("  "):
                    if line.startswith("    "):
                        logging.debug("Adding %s as it belongs to workflow_dispatch block", line)
                        out_lines.append(line)
                    else:
                        logging.debug("Moving to ON_BLOCK as line doesn't start with 4 spaces: %s", line)
                        parser_location = ParserLocation.ON_BLOCK
                else:
                    logging.debug("Line not starting with two spaces, moving from workflow_dispatch block to normal and appending %s", line)
                    parser_location = ParserLocation.NORMAL
                    out_lines.append(line)
    return '\n'.join(out_lines) + '\n'


def test_workflow_dispatch_remains_unchanged_and_other_triggers_are_removed() -> None:
    example_workflow_def = dedent("""
    name: buh

    on:
      something:
        some_parameter: yes
      workflow_dispatch:
        inputs:
          bla
      something_else:
        another_parameter: no
    
    jobs:
      - one
    """)
    expected_result = dedent("""
    name: buh

    on:
      workflow_dispatch:
        inputs:
          bla
    
    jobs:
      - one
    """)
    assert convert_to_workflow_dispatch(example_workflow_def) == expected_result

def test_other_triggers_are_removed_and_workflow_dispatch_is_added() -> None:
    example_workflow_def = dedent("""
    name: buh

    on:
      something:
        some_parameter: yes
      something_else:
        another_parameter: no
    
    jobs:
      - one
    """)
    expected_result = dedent("""
    name: buh

    on:
      workflow_dispatch:
    
    jobs:
      - one
    """)
    assert convert_to_workflow_dispatch(example_workflow_def) == expected_result


def main() -> None:
    if len(sys.argv) == 2 and sys.argv[1] == "--debug":
        logging.basicConfig(level=logging.DEBUG)
        test_workflow_dispatch_remains_unchanged_and_other_triggers_are_removed()
        test_other_triggers_are_removed_and_workflow_dispatch_is_added()
    else:
        for workflow_file in workflows_folder.glob("*.yml"):
            with workflow_file.open() as fh:
                contents = fh.read()
            with workflow_file.open("w") as fh:
                fh.write(convert_to_workflow_dispatch(contents))
                

if __name__ == "__main__":
    main()
