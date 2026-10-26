import 'package:flutter_gemma/flutter_gemma.dart';

const List<Tool> functionGemmaTools = <Tool>[
  Tool(
    name: 'add_transaction',
    description:
        'Record an expense or income transaction in an existing wallet.',
    parameters: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'amount': <String, dynamic>{'type': 'integer', 'minimum': 1},
        'transaction_type': <String, dynamic>{
          'type': 'string',
          'enum': <String>['expense', 'income'],
        },
        'wallet_id': <String, dynamic>{'type': 'integer'},
        'category_id': <String, dynamic>{'type': 'integer'},
        'note': <String, dynamic>{'type': 'string'},
        'merchant': <String, dynamic>{'type': 'string'},
        'exclude_from_target': <String, dynamic>{'type': 'boolean'},
      },
      'required': <String>['amount', 'transaction_type', 'wallet_id'],
    },
  ),
  Tool(
    name: 'create_category',
    description: 'Create a new expense or income category.',
    parameters: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'name': <String, dynamic>{'type': 'string'},
        'category_type': <String, dynamic>{
          'type': 'string',
          'enum': <String>['expense', 'income'],
        },
      },
      'required': <String>['name', 'category_type'],
    },
  ),
  Tool(
    name: 'set_wallet_balance',
    description: 'Set the current balance of an existing wallet.',
    parameters: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'wallet_id': <String, dynamic>{'type': 'integer'},
        'target_balance': <String, dynamic>{'type': 'integer', 'minimum': 0},
      },
      'required': <String>['wallet_id', 'target_balance'],
    },
  ),
  Tool(
    name: 'transfer',
    description: 'Transfer money between two existing wallets.',
    parameters: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'amount': <String, dynamic>{'type': 'integer', 'minimum': 1},
        'from_wallet_id': <String, dynamic>{'type': 'integer'},
        'to_wallet_id': <String, dynamic>{'type': 'integer'},
      },
      'required': <String>['amount', 'from_wallet_id', 'to_wallet_id'],
    },
  ),
  Tool(
    name: 'create_wallet',
    description: 'Create a new wallet.',
    parameters: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'name': <String, dynamic>{'type': 'string'},
        'initial_balance': <String, dynamic>{'type': 'integer', 'minimum': 0},
      },
      'required': <String>['name'],
    },
  ),
  Tool(
    name: 'set_spending_target',
    description: 'Set the spending limit for a month.',
    parameters: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'month': <String, dynamic>{
          'type': 'string',
          'pattern': r'^\d{4}-\d{2}$',
        },
        'amount': <String, dynamic>{'type': 'integer', 'minimum': 1},
      },
      'required': <String>['month', 'amount'],
    },
  ),
  Tool(
    name: 'query_total',
    description: 'Read the total expense for a period.',
    parameters: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'period': <String, dynamic>{
          'type': 'string',
          'enum': <String>['today', 'week', 'month'],
        },
        'category_id': <String, dynamic>{'type': 'integer'},
      },
      'required': <String>['period'],
    },
  ),
  Tool(
    name: 'ask_clarification',
    description: 'Ask the user for missing or ambiguous information.',
    parameters: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'question': <String, dynamic>{'type': 'string'},
        'options': <String, dynamic>{
          'type': 'array',
          'items': <String, dynamic>{'type': 'string'},
        },
      },
      'required': <String>['question'],
    },
  ),
];
