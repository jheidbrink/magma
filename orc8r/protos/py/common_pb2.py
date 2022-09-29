# -*- coding: utf-8 -*-
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: common.proto
"""Generated protocol buffer code."""
from google.protobuf.internal import enum_type_wrapper
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from google.protobuf import reflection as _reflection
from google.protobuf import symbol_database as _symbol_database
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()




DESCRIPTOR = _descriptor.FileDescriptor(
  name='common.proto',
  package='magma.orc8r',
  syntax='proto3',
  serialized_options=b'Z\031magma/orc8r/lib/go/protos',
  create_key=_descriptor._internal_create_key,
  serialized_pb=b'\n\x0c\x63ommon.proto\x12\x0bmagma.orc8r\"\x06\n\x04Void\"\x14\n\x05\x42ytes\x12\x0b\n\x03val\x18\x01 \x01(\x0c\"\x17\n\tNetworkID\x12\n\n\x02id\x18\x01 \x01(\t\"\x15\n\x06IDList\x12\x0b\n\x03ids\x18\x01 \x03(\t*B\n\x08LogLevel\x12\t\n\x05\x44\x45\x42UG\x10\x00\x12\x08\n\x04INFO\x10\x01\x12\x0b\n\x07WARNING\x10\x02\x12\t\n\x05\x45RROR\x10\x03\x12\t\n\x05\x46\x41TAL\x10\x04\x42\x1bZ\x19magma/orc8r/lib/go/protosb\x06proto3'
)

_LOGLEVEL = _descriptor.EnumDescriptor(
  name='LogLevel',
  full_name='magma.orc8r.LogLevel',
  filename=None,
  file=DESCRIPTOR,
  create_key=_descriptor._internal_create_key,
  values=[
    _descriptor.EnumValueDescriptor(
      name='DEBUG', index=0, number=0,
      serialized_options=None,
      type=None,
      create_key=_descriptor._internal_create_key),
    _descriptor.EnumValueDescriptor(
      name='INFO', index=1, number=1,
      serialized_options=None,
      type=None,
      create_key=_descriptor._internal_create_key),
    _descriptor.EnumValueDescriptor(
      name='WARNING', index=2, number=2,
      serialized_options=None,
      type=None,
      create_key=_descriptor._internal_create_key),
    _descriptor.EnumValueDescriptor(
      name='ERROR', index=3, number=3,
      serialized_options=None,
      type=None,
      create_key=_descriptor._internal_create_key),
    _descriptor.EnumValueDescriptor(
      name='FATAL', index=4, number=4,
      serialized_options=None,
      type=None,
      create_key=_descriptor._internal_create_key),
  ],
  containing_type=None,
  serialized_options=None,
  serialized_start=107,
  serialized_end=173,
)
_sym_db.RegisterEnumDescriptor(_LOGLEVEL)

LogLevel = enum_type_wrapper.EnumTypeWrapper(_LOGLEVEL)
DEBUG = 0
INFO = 1
WARNING = 2
ERROR = 3
FATAL = 4



_VOID = _descriptor.Descriptor(
  name='Void',
  full_name='magma.orc8r.Void',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  create_key=_descriptor._internal_create_key,
  fields=[
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  serialized_options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=29,
  serialized_end=35,
)


_BYTES = _descriptor.Descriptor(
  name='Bytes',
  full_name='magma.orc8r.Bytes',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  create_key=_descriptor._internal_create_key,
  fields=[
    _descriptor.FieldDescriptor(
      name='val', full_name='magma.orc8r.Bytes.val', index=0,
      number=1, type=12, cpp_type=9, label=1,
      has_default_value=False, default_value=b"",
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  serialized_options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=37,
  serialized_end=57,
)


_NETWORKID = _descriptor.Descriptor(
  name='NetworkID',
  full_name='magma.orc8r.NetworkID',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  create_key=_descriptor._internal_create_key,
  fields=[
    _descriptor.FieldDescriptor(
      name='id', full_name='magma.orc8r.NetworkID.id', index=0,
      number=1, type=9, cpp_type=9, label=1,
      has_default_value=False, default_value=b"".decode('utf-8'),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  serialized_options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=59,
  serialized_end=82,
)


_IDLIST = _descriptor.Descriptor(
  name='IDList',
  full_name='magma.orc8r.IDList',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  create_key=_descriptor._internal_create_key,
  fields=[
    _descriptor.FieldDescriptor(
      name='ids', full_name='magma.orc8r.IDList.ids', index=0,
      number=1, type=9, cpp_type=9, label=3,
      has_default_value=False, default_value=[],
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  serialized_options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=84,
  serialized_end=105,
)

DESCRIPTOR.message_types_by_name['Void'] = _VOID
DESCRIPTOR.message_types_by_name['Bytes'] = _BYTES
DESCRIPTOR.message_types_by_name['NetworkID'] = _NETWORKID
DESCRIPTOR.message_types_by_name['IDList'] = _IDLIST
DESCRIPTOR.enum_types_by_name['LogLevel'] = _LOGLEVEL
_sym_db.RegisterFileDescriptor(DESCRIPTOR)

Void = _reflection.GeneratedProtocolMessageType('Void', (_message.Message,), {
  'DESCRIPTOR' : _VOID,
  '__module__' : 'common_pb2'
  # @@protoc_insertion_point(class_scope:magma.orc8r.Void)
  })
_sym_db.RegisterMessage(Void)

Bytes = _reflection.GeneratedProtocolMessageType('Bytes', (_message.Message,), {
  'DESCRIPTOR' : _BYTES,
  '__module__' : 'common_pb2'
  # @@protoc_insertion_point(class_scope:magma.orc8r.Bytes)
  })
_sym_db.RegisterMessage(Bytes)

NetworkID = _reflection.GeneratedProtocolMessageType('NetworkID', (_message.Message,), {
  'DESCRIPTOR' : _NETWORKID,
  '__module__' : 'common_pb2'
  # @@protoc_insertion_point(class_scope:magma.orc8r.NetworkID)
  })
_sym_db.RegisterMessage(NetworkID)

IDList = _reflection.GeneratedProtocolMessageType('IDList', (_message.Message,), {
  'DESCRIPTOR' : _IDLIST,
  '__module__' : 'common_pb2'
  # @@protoc_insertion_point(class_scope:magma.orc8r.IDList)
  })
_sym_db.RegisterMessage(IDList)


DESCRIPTOR._options = None
# @@protoc_insertion_point(module_scope)
