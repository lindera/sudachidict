# SudachiDict for Lindera

This repository is a mirror of the [SudachiDict](https://github.com/WorksApplications/SudachiDict)
raw lexicon files, together with the supporting files needed to build them as a
[Lindera](https://github.com/lindera/lindera) dictionary. It exists to pin the
exact inputs of Lindera dictionary builds for reproducibility and availability,
following the same convention as
[lindera/unidic-mecab](https://github.com/lindera/unidic-mecab) and
[lindera/mecab-ipadic](https://github.com/lindera/mecab-ipadic).

Current version: **0.1.0-20260723**, version 0.1.0 of this repository with
SudachiDict 20260723 (upstream tag
[v20260723](https://github.com/WorksApplications/SudachiDict/releases/tag/v20260723)).

## Versions

A tag is `<version of this repository>-<SudachiDict version>`. Tag `20260723`
predates this scheme.

| Tag | `char.def` | Lindera |
| --- | --- | --- |
| `0.1.0-20260723` | Sudachi's (sudachi.rs `v0.7.0`) | 7.0.0 or later, which reads it with `"char_def_format": "sudachi"` ([lindera/lindera#1388](https://github.com/lindera/lindera/issues/1388)) |
| `20260723` | unidic-mecab 2.1.2's | 6.0.0 to 6.2.0 |

The lexicons, `matrix.def` and `unk.def` are the same in both.

## Contents

| File | Origin | License |
| --- | --- | --- |
| `small_lex.csv` | SudachiDict raw distribution | Apache-2.0 (UniDic-derived, see `LEGAL`) |
| `core_lex.csv` | SudachiDict raw distribution | Apache-2.0 (NEologd-derived, see `LEGAL`) |
| `notcore_lex.csv` | SudachiDict raw distribution | Apache-2.0 (NEologd-derived, see `LEGAL`) |
| `matrix.def` | SudachiDict raw distribution (byte-identical to the UniDic 2.1.2 matrix) | BSD/GPL/LGPL triple license (see `COPYING`) |
| `char.def` | sudachi.rs `v0.7.0` (`resources/char.def`) | Apache-2.0 (sudachi.rs), derived from UniDic's `char.def` (see below) |
| `unk.def` | unidic-mecab 2.1.2 source archive, **modified** (see below) | BSD/GPL/LGPL triple license (see `COPYING`) |
| `LEGAL`, `LICENSE-2.0.txt` | SudachiDict upstream (`v20260723`) | — |
| `BSD`, `COPYING`, `GPL`, `LGPL` | unidic-mecab 2.1.2 source archive | — |

Large files (`*.csv`, `matrix.def`) are tracked with Git LFS.

## Sources

SudachiDict raw lexicons and connection matrix, retrieved on 2026-08-25 from
the official distribution bucket
(`https://sudachi.s3.ap-northeast-1.amazonaws.com/sudachidict-raw/`):

| Archive | SHA-256 |
| --- | --- |
| `20260723/small_lex.zip` | `b578ac9545899783d5d7e30d5d78d5d9dcf40b36965d4af0663ec2eb041c1093` |
| `20260723/core_lex.zip` | `a2b39e1572adab08a649b1390b134517adc55f1d733c59358b113298788bf31c` |
| `20260723/notcore_lex.zip` | `a15edc5193b42acfebdc220825d8c7edf0059bf950169d09bcdf6c426a81ecd1` |
| `matrix.def.zip` | `3ccaed582481b31be170c7200cf1cb2856f2d14c2fa601b3692d97dbad5a3bd1` |

`char.def` is the character definition that Sudachi uses, retrieved on
2026-11-17 from sudachi.rs `v0.7.0`
(`https://github.com/WorksApplications/sudachi.rs/blob/v0.7.0/resources/char.def`).
Sudachi `v0.8.2` ships the same bytes (`src/main/resources/char.def`). It is
UniDic's `char.def` with Sudachi's changes, and it uses syntax that only Sudachi
reads: the `NOOOVBOW` and `NOOOVEOW` flags, `ALL`, and overlapping ranges that
add up. Lindera reads it with `"char_def_format": "sudachi"` in the
dictionary's `metadata.json`.

`unk.def` is taken from the unidic-mecab 2.1.2 source archive
(`https://lindera.dev/unidic-mecab-2.1.2.tar.gz`, mirrored at
[lindera/unidic-mecab](https://github.com/lindera/unidic-mecab)), because
SudachiDict entries use UniDic 2.1.2 context IDs. Before the modification
below, it is byte-identical to sudachi.rs `v0.7.0` `resources/unk.def`.

Checksums of the files as committed:

| File | SHA-256 |
| --- | --- |
| `small_lex.csv` | `6cc54808a2359b48fe15105814ca3352dceb4c25305f6956b7a104f7f6611f00` |
| `core_lex.csv` | `3a3c4b68cf0b64893dff6cc14ba690d79a99fefe1564dd751a418317db2e148d` |
| `notcore_lex.csv` | `6237df5751fea79e638dba54d088520ec3e2386209971e737c6ecc5d69f24950` |
| `matrix.def` | `b20e0da1ed5472e0be2e5cb3c716672fd788e1701e08d54624b58ba52d73d927` |
| `char.def` | `3fcb45c133b9f59d77ed052931f3a19dbcf884a91289e546071a826038342d5d` |
| `unk.def` | `97fec17d4f477ee94cc25f1a1c318cec8ea4688491581c069d61677e9e2ad976` |

## Modifications

All files are unmodified from their upstream distributions, with one
exception: `unk.def` has a placeholder display-surface column inserted after
the four reserved columns, so that unknown words expose their morphological
details at the same column indices as SudachiDict's 19-column lexicon rows
(SudachiDict rows carry the display surface at column 4, 0-based; UniDic's
`unk.def` has its part-of-speech there).

The exact transformation applied to the original unidic-mecab 2.1.2
`unk.def`:

```shell
awk -F, 'BEGIN{OFS=","} {out=$1 OFS $2 OFS $3 OFS $4 OFS "*"; for(i=5;i<=NF;i++) out=out OFS $i; print out}' unk.def
```

## Releases

Pushing a tag runs `.github/workflows/release.yml`. It builds
`sudachidict-<tag>.tar.gz` with `git archive` from a checkout with the Git LFS
files, because GitHub's own source archive holds the LFS pointers instead of
the files. It checks the archive against the commit with
`.github/scripts/check-archive.sh`, then publishes it with its SHA-256 to the
GitHub release and to `https://lindera.dev/sudachidict-<tag>.tar.gz`.

- The archive has the top directory `sudachidict-<tag>/` and leaves out
  `.gitattributes`, `.markdownlint.json` and `.github/`.
- The workflow does not replace an archive that lindera.dev already serves,
  because Lindera builds pin its SHA-256.

The archive of tag `20260723` (`https://lindera.dev/sudachidict-20260723.tar.gz`)
was made by hand before the workflow existed.

## Building a Lindera dictionary

See the SudachiDict page of the Lindera documentation:
<https://lindera.github.io/lindera/sudachidict.html>

## Licenses

- The SudachiDict lexicon files are distributed under the Apache License 2.0
  (`LICENSE-2.0.txt`). See `LEGAL` for the full attribution of the UniDic and
  NEologd data they incorporate.
- `char.def` is distributed by sudachi.rs under the Apache License 2.0
  (`LICENSE-2.0.txt`). It is derived from UniDic's `char.def`, whose header it
  keeps (`$Id: char.def 9 2012-12-12 04:13:15Z togiso $`); UniDic is
  triple-licensed under BSD/GPL/LGPL (`BSD`, `GPL`, `LGPL`; see `COPYING`).
- `matrix.def` and `unk.def` are part of UniDic (unidic-mecab 2.1.2), which is
  triple-licensed under BSD/GPL/LGPL (`BSD`, `GPL`, `LGPL`; see `COPYING`).

This repository is not affiliated with or endorsed by Works Applications
Co., Ltd. "Sudachi" and "SudachiDict" are the work of the WAP Tokushima
Laboratory of AI and NLP.
