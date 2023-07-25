## Project Summary:
- Multi-touch marketing attribution is a technique used to weight specific marketing campaigns associated with customer sessions that lead to a purchase.
    - By multi-touch, we mean that we examine a series of User Sessions (or "touch points") associated that lead to a purchase.
    - Each Session is associated with a marketing campaign - e.g. A user clicks on an email to land on our ecommerce site.
    - Typically we think of the first session in time to be critical, as well as the session that occurs right before a purchase.
    - Sessions towards the middle of the series of sessions are viewed as having had less impact on the user's decision to make a purchase.
    - Rather than giving credit to a single marketing campaign for a given purchase, multi-touch models take into account several sessions leading up to a purchase.
- For this project, I demonstrate how to weight a 7-day history of user sessions leading to a purchase so that the first and last sessions are given the same weight, decaying exponentially to the middle session(s), which are weighted the least.
- To simplify the example, I will assign these generic digital marketing channels to each User Session without reference to specific campaigns.
    - (`'OrganicSearch', 'Direct', 'Social', 'PaidSearch', 'Email'`)
- In practice, marketing channels are simply a given medium (Email) used for a single marketing campaign (e.g., a Christmas 2023 Email Blast).

## Contents:
- attrib_model.ipynb: Complete notebook that should run as long as you include the .csv and .sqlite files when run locally
- attrib_model_toy_data.csv: toy dataset
- attrib_mode.sqlite: SQLite file that tables are written to
- dev_code: 
  - My original postgreSQL code in the file `dbt_format_ver_2.sql` was written for specific marketing data, whereas my completed Jupyter notebook in the main folder, `attrib_model.ipynb` uses a toy dataset and is much easier to understand and clearly documented.
  - `sarraille_marketingmodel.md` is a first draft of my tutorial using the toy data, which was developed into `attrib_model.ipynb`

## To-Do:
- Add graph, visualization of weighted events