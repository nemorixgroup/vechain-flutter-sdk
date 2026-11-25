/// The official BIP-32 test vectors 1 and 2, converted from
/// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki
///
/// Each `xprv` was Base58Check-decoded (checksum verified) into its raw
/// chain code and private key. The compressed public key is derived
/// from that private key.
const bip32TestVectors = <({
  int vector,
  String seed,
  String path,
  String chainCode,
  String privateKey,
  String publicKey,
})>[
  (
    vector: 1,
    seed: '0x000102030405060708090a0b0c0d0e0f',
    path: 'm',
    chainCode:
        '0x873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508',
    privateKey:
        '0xe8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35',
    publicKey:
        '0x0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2',
  ),
  (
    vector: 1,
    seed: '0x000102030405060708090a0b0c0d0e0f',
    path: "m/0'",
    chainCode:
        '0x47fdacbd0f1097043b78c63c20c34ef4ed9a111d980047ad16282c7ae6236141',
    privateKey:
        '0xedb2e14f9ee77d26dd93b4ecede8d16ed408ce149b6cd80b0715a2d911a0afea',
    publicKey:
        '0x035a784662a4a20a65bf6aab9ae98a6c068a81c52e4b032c0fb5400c706cfccc56',
  ),
  (
    vector: 1,
    seed: '0x000102030405060708090a0b0c0d0e0f',
    path: "m/0'/1",
    chainCode:
        '0x2a7857631386ba23dacac34180dd1983734e444fdbf774041578e9b6adb37c19',
    privateKey:
        '0x3c6cb8d0f6a264c91ea8b5030fadaa8e538b020f0a387421a12de9319dc93368',
    publicKey:
        '0x03501e454bf00751f24b1b489aa925215d66af2234e3891c3b21a52bedb3cd711c',
  ),
  (
    vector: 1,
    seed: '0x000102030405060708090a0b0c0d0e0f',
    path: "m/0'/1/2'",
    chainCode:
        '0x04466b9cc8e161e966409ca52986c584f07e9dc81f735db683c3ff6ec7b1503f',
    privateKey:
        '0xcbce0d719ecf7431d88e6a89fa1483e02e35092af60c042b1df2ff59fa424dca',
    publicKey:
        '0x0357bfe1e341d01c69fe5654309956cbea516822fba8a601743a012a7896ee8dc2',
  ),
  (
    vector: 1,
    seed: '0x000102030405060708090a0b0c0d0e0f',
    path: "m/0'/1/2'/2",
    chainCode:
        '0xcfb71883f01676f587d023cc53a35bc7f88f724b1f8c2892ac1275ac822a3edd',
    privateKey:
        '0x0f479245fb19a38a1954c5c7c0ebab2f9bdfd96a17563ef28a6a4b1a2a764ef4',
    publicKey:
        '0x02e8445082a72f29b75ca48748a914df60622a609cacfce8ed0e35804560741d29',
  ),
  (
    vector: 1,
    seed: '0x000102030405060708090a0b0c0d0e0f',
    path: "m/0'/1/2'/2/1000000000",
    chainCode:
        '0xc783e67b921d2beb8f6b389cc646d7263b4145701dadd2161548a8b078e65e9e',
    privateKey:
        '0x471b76e389e528d6de6d816857e012c5455051cad6660850e58372a6c3e6e7c8',
    publicKey:
        '0x022a471424da5e657499d1ff51cb43c47481a03b1e77f951fe64cec9f5a48f7011',
  ),
  (
    vector: 2,
    seed:
        '0xfffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542',
    path: 'm',
    chainCode:
        '0x60499f801b896d83179a4374aeb7822aaeaceaa0db1f85ee3e904c4defbd9689',
    privateKey:
        '0x4b03d6fc340455b363f51020ad3ecca4f0850280cf436c70c727923f6db46c3e',
    publicKey:
        '0x03cbcaa9c98c877a26977d00825c956a238e8dddfbd322cce4f74b0b5bd6ace4a7',
  ),
  (
    vector: 2,
    seed:
        '0xfffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542',
    path: 'm/0',
    chainCode:
        '0xf0909affaa7ee7abe5dd4e100598d4dc53cd709d5a5c2cac40e7412f232f7c9c',
    privateKey:
        '0xabe74a98f6c7eabee0428f53798f0ab8aa1bd37873999041703c742f15ac7e1e',
    publicKey:
        '0x02fc9e5af0ac8d9b3cecfe2a888e2117ba3d089d8585886c9c826b6b22a98d12ea',
  ),
  (
    vector: 2,
    seed:
        '0xfffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542',
    path: "m/0/2147483647'",
    chainCode:
        '0xbe17a268474a6bb9c61e1d720cf6215e2a88c5406c4aee7b38547f585c9a37d9',
    privateKey:
        '0x877c779ad9687164e9c2f4f0f4ff0340814392330693ce95a58fe18fd52e6e93',
    publicKey:
        '0x03c01e7425647bdefa82b12d9bad5e3e6865bee0502694b94ca58b666abc0a5c3b',
  ),
  (
    vector: 2,
    seed:
        '0xfffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542',
    path: "m/0/2147483647'/1",
    chainCode:
        '0xf366f48f1ea9f2d1d3fe958c95ca84ea18e4c4ddb9366c336c927eb246fb38cb',
    privateKey:
        '0x704addf544a06e5ee4bea37098463c23613da32020d604506da8c0518e1da4b7',
    publicKey:
        '0x03a7d1d856deb74c508e05031f9895dab54626251b3806e16b4bd12e781a7df5b9',
  ),
  (
    vector: 2,
    seed:
        '0xfffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542',
    path: "m/0/2147483647'/1/2147483646'",
    chainCode:
        '0x637807030d55d01f9a0cb3a7839515d796bd07706386a6eddf06cc29a65a0e29',
    privateKey:
        '0xf1c7c871a54a804afe328b4c83a1c33b8e5ff48f5087273f04efa83b247d6a2d',
    publicKey:
        '0x02d2b36900396c9282fa14628566582f206a5dd0bcc8d5e892611806cafb0301f0',
  ),
  (
    vector: 2,
    seed:
        '0xfffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542',
    path: "m/0/2147483647'/1/2147483646'/2",
    chainCode:
        '0x9452b549be8cea3ecb7a84bec10dcfd94afe4d129ebfd3b3cb58eedf394ed271',
    privateKey:
        '0xbb7d39bdb83ecf58f2fd82b6d918341cbef428661ef01ab97c28a4842125ac23',
    publicKey:
        '0x024d902e1a2fc7a8755ab5b694c575fce742c48d9ff192e63df5193e4c7afe1f9c',
  ),
];
