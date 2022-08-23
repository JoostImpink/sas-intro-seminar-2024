# SAS Seminar - September 2021

## Matching of commonly used datasets

The main datasets use different firm identifiers:

- gvkey (Compustat)
- permno (Crsp)
- Central Index Key (CIK) (Audit Analytics, SEC filings)
- IBES Ticker (IBES)

Additionally, also the ticker symbol and Cusip/sedol are commonly used, as well as the firm name itself. We will look into matching these datasets.

## Topics

In this seminar we will look into matching these datasets:

#### Using Rsubmit (local SAS) - [1_rsubmit.sas](1_rsubmit.sas)

#### Header vs historical values - Compustat - [2_compustat.sas](2_compustat.sas)

#### Matching Compustat with CRSP - [3_crsp.sas](3_crsp.sas)

#### Matching Compustat with Audit Analytics -  [4_audit_analytics.sas](4_audit_analytics.sas)

#### Matching Compustat with IBES - [5_ibes.sas](5_ibes.sas)


## SAS Studio

We will be using both SAS installed locally and SAS Studio hosted by WRDS. Both ways have their pros and cons. 

Link to SAS Studio (WRDS login required): [https://wrds-cloud.wharton.upenn.edu/SASStudio/index](https://wrds-cloud.wharton.upenn.edu/SASStudio/index)

### SAS tutorials

For some basic SAS tutorials, see [https://github.com/JoostImpink/SAS-bootcamp](https://github.com/JoostImpink/SAS-bootcamp)

