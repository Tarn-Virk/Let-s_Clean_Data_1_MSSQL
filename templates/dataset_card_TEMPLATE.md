# Dataset card: `<file name>`

Fill this in during Phase 2 (by looking at the file) and finish it in Phases 4-5 (by measuring it).
One card per file. Commit the filled cards: they are the memory of the project.

## 1. Source
| Item | Value |
|---|---|
| Original file name | |
| Where it came from / URL / date downloaded | |
| Size on disk | |
| Licence / sharing limits | |

## 2. File format (Phase 2.2)  ->  these become BULK INSERT options
| Property | Finding | BULK INSERT option |
|---|---|---|
| Delimiter | `,` `;` tab `\|` | `FIELDTERMINATOR` |
| Quote character | `"` / none | `FORMAT='CSV'`, `FIELDQUOTE` |
| Encoding | UTF-8 / UTF-8 with BOM / Windows-1252 | `CODEPAGE` (65001 = UTF-8) |
| Line ending | LF / CRLF | `ROWTERMINATOR` (`0x0a` / `\r\n`) |
| Header row | yes, row 1 | `FIRSTROW = 2` |
| Embedded line breaks inside quoted text? | yes / no | needs `FORMAT='CSV'` |
| Last line has a line break? | yes / no | |
| BOM at start? | yes / no | strip in header read |

## 3. Shape (Phase 2.3 - 2.5)
| Item | Value |
|---|---|
| Columns (from header) | |
| Data rows (counted OUTSIDE SQL) | |
| Header oddities (spaces, capitals, typos, reserved words, duplicates) | |
| Rows with a different column count | |

## 4. Body-row suspicions (Phase 2.4)
Top 20: `___`  Middle 20: `___`  Bottom 20 (complete last row?): `___`
`,,` matches: `___`  `,$` matches: `___`  placeholder text (NULL/N/A/unknown/-): `___`

## 5. Declared grain and key (decide, then PROVE in step 5.2)
"One row = one ______ per ______."   Key column(s): `______`   Proven unique? yes / no

## 6. Mandatory vs conditional columns (Phase 5.1)
Mandatory (never blank): 
Conditional (blank allowed when ...): 

## 7. Rules (Phase 5)
| Rule | Dimension | Expected violations | Found | Decision in clean layer |
|---|---|---|---|---|
| | | | | flag / reject / fix |

## 8. Clean-layer decisions (Phase 6)
Types chosen (from 6.1a, with overrides): 
Text standardisation: 
Flag codes created: 

## 9. Reconciliation numbers
File rows: ___  raw rows: ___  clean rows: ___  gold rows: ___
