"""Byggspärrarna i tools/bygg.py, utan nät och utan Codemagic."""
from __future__ import annotations

import sys
import unittest
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import bygg  # noqa: E402

GRONT = "== swift-release\nGRÖNT: 20 test, 0 fel, 1 s i testerna\n"
ROTT = "== swift-release\nRÖTT: 20 test, 2 fel, 1 s i testerna\n"
NU = datetime(2026, 10, 20, 12, 0, tzinfo=timezone.utc)


class Sparrar(unittest.TestCase):
    def setUp(self) -> None:
        self.gammalt = bygg.APP_ID
        bygg.APP_ID = "app1"

    def tearDown(self) -> None:
        bygg.APP_ID = self.gammalt

    def test_gront_och_tomt_hos_codemagic_kan_starta(self) -> None:
        self.assertEqual(bygg.hinder([], NU, GRONT), [])

    def test_rott_eller_saknat_resultat_stoppar(self) -> None:
        self.assertIn("Actions är inte grönt för main:s senaste commit", bygg.hinder([], NU, ROTT))
        self.assertIn("Actions har inget resultat för main:s senaste commit än", bygg.hinder([], NU, None))

    def test_ett_bygge_som_gar_for_en_annan_app_stoppar(self) -> None:
        idunn = {"appId": "annan", "_app": "Idunn", "workflowId": "ios-testflight", "status": "building"}
        stopp = bygg.hinder([idunn], NU, GRONT)
        self.assertTrue(any(s.startswith("ett bygge går redan") for s in stopp), stopp)

    def test_dagens_bygge_redan_gjort(self) -> None:
        idag = {"appId": "app1", "workflowId": "ios-testflight", "status": "finished",
                "startedAt": "2026-10-20T08:00:00Z", "finishedAt": "2026-10-20T08:05:00Z"}
        self.assertTrue(any("dagens bygge" in s for s in bygg.hinder([idag], NU, GRONT)))
        self.assertFalse(any("dagens bygge" in s for s in bygg.hinder([idag], NU, GRONT, igen=True)))

    def test_utan_app_id_startar_inget(self) -> None:
        bygg.APP_ID = ""
        self.assertTrue(any("APP_ID saknas" in s for s in bygg.hinder([], NU, GRONT)))

    def test_bara_dokument_kraver_ingen_ny_korning(self) -> None:
        self.assertTrue(bygg.utan_ci(["CLAUDE.md", "PLAN.md", "codemagic.yaml"]))
        self.assertFalse(bygg.utan_ci(["CLAUDE.md", "HoppKit/Sources/Jump/JumpMath.swift"]))


if __name__ == "__main__":
    unittest.main()
