/// Phase 1 - 0.0.2-dev: Network configuration.
///
/// Every VeChainThor transaction carries a chain tag, the last byte of
/// the network's genesis block ID, so it can only be executed on the
/// network it was signed for. VeChainNetwork bundles that identity with
/// the node URL the SDK talks to.
///
/// // Full technical decisions:
/// https://github.com/nemorixgroup/VeChain-Knowledge-Base/tree/main/docs-sdk/phase-1/network-configuration
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

void networkConfigurationExample() {
  // The three official networks are predefined, ready to use.
  for (final network in [
    VeChainNetwork.mainnet,
    VeChainNetwork.testnet,
    VeChainNetwork.solo,
  ]) {
    print(network);
  }

  // The chain tag is derived from the genesis ID, never stored apart,
  // so the two can never disagree.
  const testnet = VeChainNetwork.testnet;
  print('Testnet genesis ID ends in: '
      '${testnet.genesisId.substring(testnet.genesisId.length - 2)}');
  print('Testnet chain tag: 0x${testnet.chainTag.toRadixString(16)}');

  // A custom network points to your own node. Inputs are validated and
  // normalized: the genesis ID goes to lowercase, trailing slashes go.
  final myNode = VeChainNetwork.custom(
    name: 'my-mainnet-node',
    genesisId:
        '0x00000000851CAF3CFDB6E899CF5958BFB1AC3413D346D43539627E6BE7EC1B4A',
    nodeUrl: 'https://my-node.example.com/',
  );
  print('Custom network: $myNode');

  // Invalid inputs are rejected with a clear error, never silently
  // accepted.
  try {
    VeChainNetwork.custom(
      name: 'broken',
      genesisId: '0x1234',
      nodeUrl: 'https://my-node.example.com',
    );
  } on VeChainNetworkException catch (e) {
    print('Expected validation error: ${e.message}');
  }
}
