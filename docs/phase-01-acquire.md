# Phase 1 - Acquire the data safely

Goal: have an untouched original and a working copy, and never confuse the two.

| Step | Do this | Why |
|---|---|---|
| 1.1 | Create the project folder with `01_raw`, `02_working`, `03_outputs` (this repo already has them). Pick a short path without spaces, for example `C:\bsg-playbook\`. | BULK INSERT reads by full path; short paths mean fewer typing mistakes. SQL Server must be able to reach it (Phase 3 "Permissions"). |
| 1.2 | Download the dataset. Olist: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce , Download button (top right), accept the dataset terms if asked. You get `archive.zip` (about 45 MB). For any other dataset: save the file exactly as the source gives it. | |
| 1.3 | Put `archive.zip` into `01_raw`. **Keep the zip.** Unzip a copy into `01_raw\archive\`. | The zip is the original evidence. If a CSV is ever damaged you re-extract it. |
| 1.4 | Never open the CSVs in Excel. | See below. |

## Why never Excel
Excel changes data silently, and saving makes it permanent:
* strips leading zeros (zip code `01310` becomes `1310`, SKU `00123` becomes `123`)
* re-reads dates by locale (`01/02/2026` is 1 Feb in the UK and 2 Jan in the US)
* turns long numbers into scientific notation (`12345678901234` becomes `1.23E+13`)
* auto-converts text that looks like a date (gene `SEPT1` becomes `1-Sep`)
* re-saves in another encoding (UTF-8 to Windows-1252: `Sao Paulo` accent characters turn into `?`)
* shows only the first ~1 million rows and does not tell you the rest exist (the Olist geolocation file has 1,000,163)

**Rule:** look at CSVs in a text editor (VS Code), analyse them in a database, never save over them.

## Done when
* original zip is in `01_raw`
* the unzipped files are in `01_raw\archive`
* you know which file(s) you are loading (write them on a dataset card: `templates/dataset_card_TEMPLATE.md`)
