from __future__ import annotations

"""Pre-pack resolver for carousel sprite generation.

This module lets you define exact source-sprite validity checks for a given
weapon/carousel family. If the source sprites match a pre-pack rule, the
resolver loads the prebuilt carousel assets from:

	./modules/prepacked-assets/<pack>/<prefix>*.png

and injects them into the WAD instead of generating them.

Matching rules are exact:
- A listed lump name with a hex hash must exist and match that hash.
- A listed lump name with value None must NOT exist.
- Lump names not mentioned in the rule are ignored.


"""

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple, Any, TypedDict
import hashlib
import re

try:
	# Optional: if omgifol is available, we can create a generic Lump when
	# there is no existing lump type to mirror.
	from omg import Lump  # type: ignore
except Exception:  # pragma: no cover
	Lump = None  # type: ignore


# -----------------------------------------------------------------------------
# Registry
# -----------------------------------------------------------------------------

@dataclass(frozen=True)
class PrepackRule:
	"""One validity rule for a prepacked asset pack.

	Attributes:
		pack: Folder under ./modules/prepacked-assets/ (e.g. "chexquest")
		expected: Mapping of source lump name -> expected SHA-256 hex digest.
			Use None to require the lump to be absent.
		note: Optional free-form note for humans.
	"""

	pack: str
	expected: Dict[str, Optional[str]]
	note: str = ""


class PackRuleSpec(TypedDict, total=False):
    expected: Dict[str, str]
    note: str


PACK_FIRST_PREPACK_RULES: Dict[str, Dict[str, PackRuleSpec]] = {
    "chexquest": {
        "SMCSAW": {
            "expected": {
                "CSAWA0": "3f3012d41370ef1a25ad2addafd1456aad719c507342a02ef989dbeb5e0f42ea",
                "SAWGA0": "c33ce501f5168730c880d23e6c750e7f5da30e8504f20c964eb6489b7e20b44e",
                "SAWGB0": "1c048294a0216c2e4a5d2e7356207c576442ddff8ccddcf2dcf5ded802eaed4b",
                "SAWGC0": "1926ce3b57e41d1950c79c3c6691fe141578a8b654b47334fb6f6ad1805fcba4",
                "SAWGD0": "30f32030258b90ad153eec716d14b4d66c72c50fe2b84aff73ab19ba914f1052",
            },
        },
        "SMFIST": {
            "expected": {
                "CSAWA0": "3f3012d41370ef1a25ad2addafd1456aad719c507342a02ef989dbeb5e0f42ea",
                "SAWGA0": "c33ce501f5168730c880d23e6c750e7f5da30e8504f20c964eb6489b7e20b44e",
                "SAWGB0": "1c048294a0216c2e4a5d2e7356207c576442ddff8ccddcf2dcf5ded802eaed4b",
                "SAWGC0": "1926ce3b57e41d1950c79c3c6691fe141578a8b654b47334fb6f6ad1805fcba4",
                "SAWGD0": "30f32030258b90ad153eec716d14b4d66c72c50fe2b84aff73ab19ba914f1052",
            },
        },
        "SMPISG": {
            "expected": {
                "PISGA0": "3c96c838be44cb5380bb38e7c3bdcc73abd7962aca5f91aeb4127512c82c599d",
                "PISGB0": "ebc601ba6757fcc85337066f0aa0770ba479f918780af10332d622f955983192",
                "PISGC0": "e6cb7352f27d976189a1bba408f5f898cef84d03100fc611b7c8fda872252596",
            },
            "note": "Don't require unused frames",
        },
        "SMSHOT": {
            "expected": {
                "SHOTA0": "393fc3824d2fb9f816776b494ff9209f59437c1d5d51e1e04b47c052acbfbf21",
                "SHTGA0": "c1427b8e21e80f23a8e55b3f53e3e098a5f15af42e4a10bfcb59654e87f5271d",
                "SHTGB0": "cde0c40b1a49e41cb9564e08e93b2fced42686eee523b1d4851fd538e361cd68",
                "SHTGC0": "4f3cceff9e17684805986af84629eac16befb9f34608cc8f73fe6996a4aba6a5",
                "SHTGD0": "e160416632dc53665fd4f7f87fa68a1553f5c98a67b4207b9fc2faf45812e8f1",
            },
        },
        "SMMGUN": {
            "expected": {
                "MGUNA0": "f6f846a253064c101cf14b218093541726d35dd5b0f4637f4c01cf65ddce0c4a",
                "CHGGA0": "0540e0eacce8dc0aebd2d878b536cbf43218e97b6e30303bab6291ad04bb7567",
                "CHGGB0": "8967823fe026a392b468c5f960555d07331df4ac0dc97f9d367f51ae736add50",
            },
        },
        "SMLAUN": {
            "expected": {
                "LAUNA0": "64d6148eb682caa890c2e9e82ba6688bd456805d644c69c00e4e7b51aa772364",
                "MISGA0": "fb2f214dc5db06610c02eca4b7865a7ca0b6fc25abf119ef0e7bc60024d15e77",
                "MISGB0": "a53d735bb2841d578012c54a8d792c180f951d5298063444601d64bd0680e2e4",
            },
        },
        "SMPLAS": {
            "expected": {
                "PLASA0": "ed735a6ff40284e4d0b6f1b15c7b1285e732c396dfb617fdb6bb6c0f49f521be",
                "PLSGA0": "23d45339974ae09ea65e8d47f6ec75cf252ec5651e645cfb9e7f87dfd0b5a94e",
                "PLSGB0": "d00d1f56f30c637f98efafe551bd1d54b1a0bd6b5d64ee94c267ba945d5cfbd8",
            },
        },
        "SMBFGG": {
            "expected": {
                "BFUGA0": "b3e1ce1cf9224b69adf4ded9c0456845791fea4e4e9c202e283a428dcc1c7d40",
                "BFGGA0": "99cd01781a242d9a887fcda10ddc52faf1e1c3f15e0683b2b42ecae81dd307a6",
                "BFGGB0": "ced44ca97cc208a7a1b1f58ccf7dadfcd7aee0d13452df4e2a7f66d289d9e6b9",
                "BFGGC0": "d2c280fb8f1efcb5aca1acb3c97bd995aecc584a2e182d615fae0dcf96d69dae",
            },
        },
    },

    "freedoom": {
        "SMCSAW": {
            "expected": {
                "CSAWA0": "ff46cd7e2888a7910add5f371842b08c1509ed96316dac699f4d9c5c5d34b4bb",
                "SAWGA0": "577b0f56f30b907d6392464039cd6a8846bc109ec60dbb2e36de4a0f2d5619e1",
                "SAWGB0": "87bcc5d5f37df66f149dcd4b5d35fa14af3b8b1ae0611cf836b8e52cb15b0df2",
                "SAWGC0": "df747458af84bfe60ad1d24cc4f7674b87914012ffad1519928766bee288f1f9",
                "SAWGD0": "89b6803bef657d2441a15716798343512f1e1797e95b295483f62bf5cc590253",
            },
        },
        "SMFIST": {
            "expected": {
                "CSAWA0": "ff46cd7e2888a7910add5f371842b08c1509ed96316dac699f4d9c5c5d34b4bb",
                "SAWGA0": "577b0f56f30b907d6392464039cd6a8846bc109ec60dbb2e36de4a0f2d5619e1",
                "SAWGB0": "87bcc5d5f37df66f149dcd4b5d35fa14af3b8b1ae0611cf836b8e52cb15b0df2",
                "SAWGC0": "df747458af84bfe60ad1d24cc4f7674b87914012ffad1519928766bee288f1f9",
                "SAWGD0": "89b6803bef657d2441a15716798343512f1e1797e95b295483f62bf5cc590253",
            },
        },
        "SMPISG": {
            "expected": {
                "PISGA0": "03ad49df57f8212e8fdf4040069d14765229c550668a6d0610cd2f5c48e98748",
                "PISGB0": "a426d8ac0f616971ad48e822bd02e78ef9d39906bc5404ce1bd2bf6555e1a6b2",
                "PISGC0": "0bef7f33fe04d664e5751f681b22aff908a700e707c35a8c44bfe07bd5948a31",
            },
            "note": "Don't require unused frames",
        },
        "SMSHOT": {
            "expected": {
                "SHOTA0": "d751c82cd99770318f8f4d30e2e4b375eae895ac71c72a575caf149194c8bec2",
                "SHTGA0": "da3122285619a21b205b8380c9f191815b57d7d5c3d121b149578e3b6896eba8",
                "SHTGB0": "23650770fad6b5220e7d9026976edc2abe1646cf3eb22c50ce8313afe5a53e77",
                "SHTGC0": "a609c864dde337f27576631408c57bf888bb274bb3bffe5a2be3997c810a80c3",
                "SHTGD0": "38242b33970fd262746eaed3422bf08c19449868bb3e1617846fbde07a4158d3",
            },
        },
        "SMSGN2": {
            "expected": {
                "SHT2A0": "daeae482579ce3682cf66128ebf53809597bfe6ac009f0f2fcd268a74c488f0e",
                "SHT2B0": "2ad1c9ced2a23e84b8a9cf7200a63483a3dfab6f5f5b9506740e7275e141cb92",
                "SHT2C0": "85f32e69c36097cea39859a64dae533ecb0ca1a3cd5889f4717035d954743358",
                "SHT2D0": "67bb5b4c5ef92474f9770bd63e07e446018a399fee1239a0eeeaf90953e67ff6",
                "SHT2E0": "f690df7ecc3f2bff103e537da309d41da4b2ba638baad87ea66a49cd76fca53d",
                "SHT2F0": "cde95edc58328b69af757c82fcc15ee7b9b9750e3a735bdbf6e5668e9c3475d2",
                "SHT2G0": "bed6a81e14d50a66253e5d8514abc104dcb999aceda04062f7b57b39a2a4f9ab",
                "SHT2H0": "a9a4cc7be77a866749b57a4d9d52e83f5de70bb1badc5c9b854edb3f2ec1755a",
            },
        },
        "SMMGUN": {
            "expected": {
                "MGUNA0": "cd8563d674ec3f0223f5f8dfc0d9d0eefe3342c7823d1828dc47a8fc1c837fdf",
                "CHGGA0": "b4b9b92436443ea3927a222fb88c5ff47419745c66704cdd4877b0334f1fe910",
                "CHGGB0": "967d16d75c2a0d9fbe7d1106e73e10226fd31197d829c1c3d5d186c51ed3daad",
            },
        },
        "SMLAUN": {
            "expected": {
                "LAUNA0": "af4cc828326d772922f948f48811b88ff823acf54c356624e8b8f6f3df70d33e",
                "MISGA0": "300ff4c56ce65347b6b63aa30f69d2e040320496e3d8e69fb62c5f844bcab20d",
                "MISGB0": "fa151cc400c12d33a149971b005444598b455f5c8493885ad827de95554795f3",
            },
        },
        "SMPLAS": {
            "expected": {
                "PLASA0": "fde8b64268d4befa311a64b1466ea0f5db7465e692a741e101c99d663e849362",
                "PLSGA0": "63ca30560fcb0c1629a1216241608871ab379a792e9f943d0eddd086cb4f9fea",
                "PLSGB0": "7b82a6df6acb5534eaaace4eb44b1bc6eeb39601906fae77a99c10fd1a5ff8b7",
            },
        },
        "SMBFGG": {
            "expected": {
                "BFUGA0": "3c832a7a4e01adf95c8e28babd690f824aea7e5cc4d7c7206ee61c606c195177",
                "BFGGA0": "5081a78c4a1645045397d1ca8afdf27c0d27a4d91e6be70c2a54a478fd2c1a72",
                "BFGGB0": "bfbf9bb456996c1425e73a89efd2c0599e4f8a2b530c6c04e5abd091fb58feb0",
                "BFGGC0": "11320a68f0344ed8a995124fd371acedf066f87467afbf175ee1f962f9704864",
            },
        },
    },

    "batdoom": {
        "SMCSAW": {
            "expected": {
                "CSAWA0": "91345bbeaaacecabb27dc5eb10e460de27b144ded063d39051da0be100a9b452",
                "SAWGA0": "e3a56925b137e736b164d2e08ac662a64552bbe0dda32abe67cdb90c7c9dd9c2",
                "SAWGB0": "c79606523e24bf0d0bce5eb50b2fda7f6dfe0fbac9c9b84bd531aa26b7be608c",
                "SAWGC0": "804f46a51c31a493e9395b09a1c57e3d6683c3c8761bf0d37bc29ee1e1288d75",
                "SAWGD0": "b6145a003c625572cfdab078e3350fde3fbe267b60b900ebdcb5b00f9f1685bc",
            },
        },
        "SMFIST": {
            "expected": {
                "CSAWA0": "91345bbeaaacecabb27dc5eb10e460de27b144ded063d39051da0be100a9b452",
                "SAWGA0": "e3a56925b137e736b164d2e08ac662a64552bbe0dda32abe67cdb90c7c9dd9c2",
                "SAWGB0": "c79606523e24bf0d0bce5eb50b2fda7f6dfe0fbac9c9b84bd531aa26b7be608c",
                "SAWGC0": "804f46a51c31a493e9395b09a1c57e3d6683c3c8761bf0d37bc29ee1e1288d75",
                "SAWGD0": "b6145a003c625572cfdab078e3350fde3fbe267b60b900ebdcb5b00f9f1685bc",
            },
        },
        "SMPISG": {
            "expected": {
                "PISGA0": "e34876eded97ed10f12bf4d64d2b753336d66e5ca88378175637ff417313a0f7",
                "PISGB0": "853ec79abe7a006339521a11d794b3942619243e4f26b69ebe75bae18e077ed2",
                "PISGC0": "cd762751716db9d3910b68f7e384cf71e921d6ba2b521ddf42ef1358346ab615",
            },
            "note": "Don't require unused frames",
        },
        "SMSHOT": {
            "expected": {
                "SHOTA0": "4e1f8fe4a66e7769cdd402a56b71b10b2cc4e926c88e14b86c576f06ebe2d91c",
                "SHTGA0": "b3f8b2784bc1d2447d49bbba31b09ca8d469b14c272ec2b2780aa42e09b4fa09",
                "SHTGB0": "221c93ed16157861a64722fcf9c2e3f673cabec7cf4f2ae42c28520e098846df",
                "SHTGC0": "5002f3f2d30c4ede286593a2ed5e40782a0ab2d06688343a79fa8c0144bb5bc9",
                "SHTGD0": "73648eaf8b9d0bed65cde167b3063b0221611c356bf1a623a205b05e99aeb6a1",
            },
        },
        "SMSGN2": {
            "expected": {
                "SHT2A0": "1b318aa22a1e55413e3708f5e5d37dde214d795892248c535e040dc5fea67182",
                "SHT2B0": "c9605419d4088d50af6b0a480c0572a8e86deb71505250133f0c6ec0ce11a987",
                "SHT2C0": "f3826083bfd9c4a570efa68e63ccf4abacabc42f4cb062e4b10d73d7fc841462",
                "SHT2D0": "0bae850e89ac7372a9b4523cc0ae9d272e960c908ffff22ddda9a6bd73009b11",
                "SHT2E0": "cd8552468c0eee0b487cb89a62f2c9ee7b725b87ee69efa467f3b10a5322877c",
                "SHT2F0": "431df16f2798abd3de82ce570ce659a84cad598a3803c3b2d2a582207e5ebd09",
                "SHT2G0": "17aa4f64e40d7c434026956a9325922bfe0ea69e5bfaa1382cb0215016e8d845",
                "SHT2H0": "6ea016798f552fa3ccd8b7bdcdb28345848e31a1711ebccdbbfcdafe43af7e5c",
            },
        },
        "SMMGUN": {
            "expected": {
                "MGUNA0": "9e92e519aba370e930f93db7c6cfbdbfd8303e229f01297c4be12ca6ee938ea7",
                "CHGGA0": "fb3decb91d70438b980aceebe4fc482a364e00ad40c18cde32bfe0a21a875c55",
                "CHGGB0": "079bee602f8001117de45772bbf7182e9736c595ff75b140403c8992758babaa",
            },
        },
        "SMLAUN": {
            "expected": {
                "LAUNA0": "e95b1c9ce2811f9ab14dd529a0bcef3bebb638de41cbfb06586f89307e3f82a4",
                "MISGA0": "7a425aede72b914eb377e67acdb5374e8a6393221a7bdbba7d2dbce673dd77b0",
                "MISGB0": "c041144bda8ac2390676038879e9165faf19a77005b54f7e31fa83959200f7b4",
            },
        },
        "SMPLAS": {
            "expected": {
                "PLASA0": "becb15daad0f713ba607bf68f6bbf135873e14d4e66859471069551de1bc31a2",
                "PLSGA0": "3c49c9eadbf8fbcef081f3153de2d0a20b0254ba88063d0a349b54b0b0d0caee",
                "PLSGB0": "399b34bf5f1c4d541862931a0684df122ed13a5786d6730675e7c27ca91e8af1",
            },
        },
        "SMBFGG": {
            "expected": {
                "BFUGA0": "5560caf00f20327dffa53d776731db3edc90a633ae42b8fd616f0f7228134f2c",
                "BFGGA0": "99ccd212b9f327c95b44f6d76add9a1c86ee9610bfdf2c41de1d39de5166ea5a",
                "BFGGB0": "82fe0b08027e9452709e80c803871bec52c5559e77f596a6aa578fb690749467",
                "BFGGC0": "51e80dfa2867574e101f5942d38f1abd7e2ed0692286911d50db0e15f3512805",
            },
		},
    },
}


def compile_prepack_rules(
    pack_first: Dict[str, Dict[str, PackRuleSpec]]
) -> Dict[str, List["PrepackRule"]]:
    compiled: Dict[str, List["PrepackRule"]] = {}

    for pack, rule_map in pack_first.items():
        for rule_name, spec in rule_map.items():
            kwargs = {"pack": pack, "expected": spec["expected"]}
            if "note" in spec:
                kwargs["note"] = spec["note"]

            compiled.setdefault(rule_name, []).append(PrepackRule(**kwargs))

    return compiled


PREPACK_RULES = compile_prepack_rules(PACK_FIRST_PREPACK_RULES)

# Track which rules have already had their hashes dumped
_DUMPED_RULES: Set[Tuple[str, str]] = set()  # (weapon_key, rule_pack)

# -----------------------------------------------------------------------------
# Hashing / lookup helpers
# -----------------------------------------------------------------------------


def sha256_hex(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def _get_lump_container(wad: Any, name: str) -> Optional[Any]:
	container = getattr(wad, name, None)
	return container if isinstance(container, dict) else None

def dump_failed_rule_hashes(wad: Any, rule: PrepackRule, weapon_key: str) -> str:
	"""Return a JSON-like dump of the hashes for one failed rule.

	Format:
	  {
		"SHOTA0": ["<sha256>"],
		"SHOTA1": [],
		"SHOTB0": ["<sha256>"]
	  }
	"""
	global _DUMPED_RULES
	
	# Check if we've already dumped this rule
	rule_id = (weapon_key, rule.pack)
	if rule_id in _DUMPED_RULES:
		return ""
	
	# Mark as dumped
	_DUMPED_RULES.add(rule_id)
	
	payload: Dict[str, List[str]] = {}

	for lump_name in rule.expected.keys():
		h = hash_lump_data(wad, lump_name)
		payload[lump_name] = [h] if h is not None else []

	return json.dumps(payload, indent=2, sort_keys=True)

def get_lump_bytes(wad: Any, lump_name: str) -> Optional[bytes]:
	"""Return raw bytes for a lump if it exists in sprites/graphics/data."""
	for attr in ("sprites", "graphics", "data"):
		container = _get_lump_container(wad, attr)
		if container is not None and lump_name in container:
			lump = container[lump_name]
			data = getattr(lump, "data", None)
			if isinstance(data, (bytes, bytearray)):
				return bytes(data)
	return None


def hash_lump_data(wad: Any, lump_name: str) -> Optional[str]:
	"""Convenience helper for building registry entries."""
	data = get_lump_bytes(wad, lump_name)
	if data is None:
		return None
	return sha256_hex(data)


# -----------------------------------------------------------------------------
# Matching
# -----------------------------------------------------------------------------

def rule_matches(wad: Any, rule: PrepackRule) -> bool:
	"""Check whether the WAD exactly satisfies a prepack rule."""
	for lump_name, expected_hash in rule.expected.items():
		actual_bytes = get_lump_bytes(wad, lump_name)

		if expected_hash is None:
			# Must be missing.
			if actual_bytes is not None:
				return False
			continue

		# Must exist and match hash.
		if actual_bytes is None:
			return False
		if sha256_hex(actual_bytes) != expected_hash:
			return False

	return True


# -----------------------------------------------------------------------------
# Asset loading / installation
# -----------------------------------------------------------------------------

def _make_lump(data: bytes, reference_lump: Optional[Any] = None) -> Any:
	"""Create a lump object from bytes.

	Preference order:
	1) Same class as reference_lump
	2) omg.Lump (if available)
	3) raw bytes (last resort)
	"""
	if reference_lump is not None:
		return type(reference_lump)(data)
	if Lump is not None:
		return Lump(data)
	return data


def load_prepacked_assets_by_prefix(asset_dir: Path, prefix: str) -> Dict[str, bytes]:
	"""Load files matching prefix pattern as lump bytes.

	Searches for files in asset_dir that start with the prefix pattern.
	Example: prefix="shotgun" matches "shotgun0.png", "shotgun1.lmp", etc.
	
	File names become lump names via Path.stem:
	  shotgun0.png -> "shotgun0"
	  shotgun1.lmp -> "shotgun1"
	"""
	assets: Dict[str, bytes] = {}

	if not asset_dir.is_dir():
		return assets

	# Create a regex pattern to match files starting with the prefix
	# This allows for extensions and additional characters after the prefix
	pattern = re.compile(rf"^{re.escape(prefix)}.*$", re.IGNORECASE)

	for path in sorted(asset_dir.iterdir()):
		if not path.is_file():
			continue
		if path.name.startswith("."):
			continue
		
		# Check if filename starts with the prefix
		if pattern.match(path.name):
			assets[path.stem] = path.read_bytes()

	return assets


def install_prepacked_assets(
	wad: Any,
	assets: Dict[str, bytes],
	reference_lump: Optional[Any] = None,
) -> List[str]:
	"""Install prepacked assets into wad.graphics / wad.sprites / wad.data.

	Returns the list of lump names installed.
	"""
	installed: List[str] = []

	for lump_name, data in assets.items():
		lump_obj = _make_lump(data, reference_lump=reference_lump)
		for attr in ("graphics", "sprites", "data"):
			container = _get_lump_container(wad, attr)
			if container is not None:
				container[lump_name] = lump_obj
		installed.append(lump_name)

	return installed


# -----------------------------------------------------------------------------
# Resolver
# -----------------------------------------------------------------------------

def _any_expected_lumps_exist(wad: Any, rule: PrepackRule) -> bool:
	"""Return True if at least one lump mentioned in the rule exists."""
	for lump_name in rule.expected.keys():
		if get_lump_bytes(wad, lump_name) is not None:
			return True
	return False

def resolve_prepacked_carousel(
	wad: Any,
	weapon_key: str,
	pack_root: str = "./modules/prepacked-assets",
	reference_lump: Optional[Any] = None,
) -> Tuple[bool, str, List[str]]:
	"""Try to replace generation with a prepacked asset set.

	Args:
		wad: Source WAD (must still contain the source sprites to validate).
		weapon_key: Registry key, e.g. "SWPISG", "SWSHOT", "SWSHG2".
		pack_root: Root directory containing prepacked assets.
		reference_lump: Optional lump object used to mirror the correct lump type.

	Returns:
		(used_prepack, pack_name, installed_lump_names)
	"""
	rules = PREPACK_RULES.get(weapon_key, [])
	if not rules:
		return False, "", []

	for rule in rules:
		if not _any_expected_lumps_exist(wad, rule):
			continue

		if not rule_matches(wad, rule):
			continue

		# Now search for files with prefix = weapon_key in the pack directory
		asset_dir = Path(pack_root) / rule.pack
		# Use weapon_key as the prefix to search for files like "SWFIST*.png"
		assets = load_prepacked_assets_by_prefix(asset_dir, weapon_key)
		if not assets:
			continue

		installed = install_prepacked_assets(
			wad,
			assets,
			reference_lump=reference_lump,
		)
		return True, rule.pack, installed

	# Dump hashes for non-matching rules (only once per rule set)
	for rule in rules:
		if not _any_expected_lumps_exist(wad, rule):
			continue

		dump_output = dump_failed_rule_hashes(wad, rule, weapon_key)
		if dump_output:  # Only print if we haven't dumped this rule before
			print(f"# Failed rule: {weapon_key} / {rule.pack}")
			print(dump_output)

	return False, "", []


def reset_dumped_rules():
	"""Reset the dumped rules tracking (useful for testing)."""
	global _DUMPED_RULES
	_DUMPED_RULES.clear()


# -----------------------------------------------------------------------------
# Optional helpers for validation / debugging
# -----------------------------------------------------------------------------

def find_matching_rule(wad: Any, weapon_key: str) -> Optional[PrepackRule]:
	"""Return the first matching rule for a weapon key, or None."""
	for rule in PREPACK_RULES.get(weapon_key, []):
		if rule_matches(wad, rule):
			return rule
	return None


def dump_hashes(wad: Any, lump_names: Iterable[str]) -> Dict[str, Optional[str]]:
	"""Return a name -> hash mapping for quick registry authoring."""
	return {name: hash_lump_data(wad, name) for name in lump_names}