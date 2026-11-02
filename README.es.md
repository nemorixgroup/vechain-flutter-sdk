[![License: MIT](https://img.shields.io/badge/License-MIT-teal.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-3.x-teal.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![CI](https://github.com/nemorixgroup/vechain-flutter-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/nemorixgroup/vechain-flutter-sdk/actions)
[![Status](https://img.shields.io/badge/Status-Fase%201%20En%20Progreso-red.svg)](https://github.com/nemorixgroup/vechain-flutter-sdk/blob/main)

[English](README.md) | **Español**

# vechain_flutter_sdk

SDK nativo de Flutter/Dart para la blockchain VeChainThor.
Dart puro · Sin platform channels · MIT · pub.dev

> **Estado: Desarrollo temprano** - la API aún no es estable.
> Fase 1 (Fundamentos) en progreso. Ver
> [CHANGELOG.md](CHANGELOG.md) para más detalles.

Diseñado para ser la **base de apps móviles X-to-Earn en VeChain**:
wallets, transacciones multi-cláusula, fees dinámicos (Galactica), fee
delegation nativa (VIP-191), smart contracts e integración con
VeBetterDAO, todo en un paquete Dart nativo.

## Roadmap (v1.0.0)

| Fase | Foco | Versiones | Estado |
|------|------|-----------|--------|
| 1 | Fundamentos (redes, llaves, mnemónicos, HD wallet, keystore) | `0.1.x` | 🔄 En progreso |
| 2 | Cliente Thor REST (cuentas, bloques, recibos, fees) | `0.2.x` | ⏳ Planificado |
| 3 | Transacciones (cláusulas, intrinsic gas, legacy y dynamic fee) | `0.3.x` | ⏳ Planificado |
| 4 | Fee delegation (VIP-191, gas payer local y remoto) | `0.4.x` | ⏳ Planificado |
| 5 | Contratos y tokens (ABI, ERC-20, eventos) | `0.5.x` | ⏳ Planificado |
| 6 | Integración VeBetter (B3TR, VOT3, recompensas X2Earn) | `0.6.x` | ⏳ Planificado |
| 7 | Certificados (VIP-192) y app de ejemplo | `0.7.x` | ⏳ Planificado |
| - | Release estable | `1.0.0` | ⏳ Planificado |


## Documentación y Knowledge Base

Este SDK está construido sobre la [VeChain Knowledge Base](https://github.com/nemorixgroup/VeChain-Knowledge-Base),
una guía para principiantes sobre VeChainThor que cubre su consenso, el
modelo de dos tokens, el modelo de transacción, la fee delegation y el
ecosistema VeBetterDAO. Lectura recomendada antes de entrar a los
detalles internos del SDK.

Cada decisión de implementación detrás de este SDK (elección de
bibliotecas, estándares de codificación y verificación contra las
especificaciones oficiales) está documentada en
[docs-sdk/](https://github.com/nemorixgroup/VeChain-Knowledge-Base/tree/main/docs-sdk).

## Instalación

```yaml
# pubspec.yaml
dependencies:
  vechain_flutter_sdk: ^0.0.1-dev
```

```bash
flutter pub get
```

## Inicio rápido

Los ejemplos se agregarán con cada release, empezando por `0.0.1-dev`.

## Redes

| Red | Chain Tag | Explorer |
|-----|-----------|----------|
| Mainnet | `0x4a` | [explore.vechain.org](https://explore.vechain.org) |
| Testnet | `0x27` | [explore-testnet.vechain.org](https://explore-testnet.vechain.org) |
| Solo | `0xf6` | Nodo local |

## Contribuciones

El SDK aún no está listo para contribuciones externas.
Sigue este repositorio para recibir actualizaciones; las contribuciones
serán bienvenidas a partir de la v1.0.0.

Ver [CONTRIBUTING.md](CONTRIBUTING.md) para las futuras pautas.

## Licencia

Licenciado bajo la [Licencia MIT](LICENSE).

## Para desarrolladores de LATAM

Este SDK se desarrolla pensando en la región:

- Documentación bilingüe (inglés / español) desde el primer módulo.
- Parte del ecosistema de SDKs de Nemorix Group para infraestructura
  financiera en LATAM (Hedera, Avalanche, XRPL, Solana, Flare,
  Stronghold, VeChain).
- Desarrollado por [Nemorix Group](https://nemorixpay.com), Ohio, USA.

Síguenos para novedades: **sdks@nemorixpay.com**

## Apoya este proyecto

Si este SDK te resulta útil a ti o a tu equipo, considera apoyar su
desarrollo. Cada contribución ayuda a cubrir infraestructura,
documentación y el tiempo invertido en construir y mantener esta
herramienta open source para la comunidad de VeChain y Flutter. ¡Gracias!

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Support-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/nemorixgroupllc)
[![Sponsor](https://img.shields.io/badge/Sponsor-GitHub-EA4AAA?logo=github-sponsors&logoColor=white)](https://github.com/sponsors/nemorixgroup)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/nemorixgroupllc)

---

Construido por [Nemorix Group](https://nemorixpay.com) · MIT
