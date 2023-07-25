-- tmp_orders_sessions_bifurcate
CREATE TEMP TABLE tmp_orders_sessions_bifurcate AS
SELECT
  OrderNumber,
  OrderDate,
  OrderDateTime,
  Email,
  BrowserGUID,
  EventSessionKey,
  SessionStartDate,
  SessionStartTime,
  StoreID,
  CampaignID,
  ROW_NUMBER() OVER (PARTITION BY OrderNumber ORDER BY SessionStartTime) AS RowNumber,
  NTILE(2) OVER (PARTITION BY OrderNumber ORDER BY SessionStartTime) AS Ntile
FROM
  tmp_all_visits_all_devices_67_days_ago
WHERE
  SessionStartTime >= OrderDateTime - INTERVAL '7 days'
  AND SessionStartTime <= OrderDateTime
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;


-- Find eventsession count
CREATE TEMP TABLE tmp_orders_sessions_count_events AS
SELECT
  OrderNumber,
  OrderDate,
  OrderDateTime,
  Email,
  BrowserGUID,
  EventSessionKey,
  SessionStartDate,
  SessionStartTime,
  StoreID,
  CampaignID,
  RowNumber,
  Ntile,
  LAST_VALUE ( RowNumber) OVER ( PARTITION BY OrderNumber ORDER BY SessionStartTime ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS EventCount
FROM
  tmp_orders_sessions_bifurcate;


 -- #### ODD NUMBER EVENTS:
 -- Set where num eventsessions is ODD:
 CREATE TEMP TABLE tmp_orders_sessions_odd_num AS
 SELECT
  OrderNumber,
  OrderDate,
  OrderDateTime,
  Email,
  BrowserGUID,
  EventSessionKey,
  SessionStartDate,
  SessionStartTime,
  StoreID,
  CampaignID,
  RowNumber,
  Ntile,
  EventCount
 FROM
  tmp_orders_sessions_count_events
 WHERE
  (EventCount % 2) != 0;

 -- Re-assign Ntile so that middle number = 3:
 CREATE TEMP TABLE tmp_orders_sessions_update_ntile AS
 SELECT
  OrderNumber,
  OrderDate,
  OrderDateTime,
  Email,
  BrowserGUID,
  EventSessionKey,
  SessionStartDate,
  SessionStartTime,
  StoreID,
  CampaignID,
  RowNumber,
  CASE WHEN RowNumber = EventCount / 2 + 1 THEN 3 ELSE Ntile END AS Ntile,
  EventCount
 FROM
   tmp_orders_sessions_odd_num;

--Assign the first half NtileRow Number:
CREATE TEMP TABLE tmp_orders_sessions_assign_row_number_first_half AS
SELECT
  OrderNumber,
  OrderDate,
  OrderDateTime,
  Email,
  BrowserGUID,
  EventSessionKey,
  SessionStartDate,
  SessionStartTime,
  StoreID,
  CampaignID,
  RowNumber,
  Ntile,
  CASE WHEN Ntile = 1 OR Ntile = 3 THEN ROW_NUMBER () OVER ( PARTITION BY ORDERNUMBER ORDER BY SessionStartTime DESC) END AS NtileRow,
  EventCount
FROM
  tmp_orders_sessions_update_ntile
WHERE
  Ntile != 2;

--Assign the Second half NtileRow Number:
CREATE TEMP TABLE tmp_orders_sessions_assign_row_number_second_half AS
SELECT
  OrderNumber,
  OrderDate,
  OrderDateTime,
  Email,
  BrowserGUID,
  EventSessionKey,
  SessionStartDate,
  SessionStartTime,
  StoreID,
  CampaignID,
  RowNumber,
  Ntile,
  CASE WHEN Ntile = 2 OR Ntile = 3 THEN ROW_NUMBER () OVER ( PARTITION BY OrderNumber ORDER BY SessionStartTime) END AS NtileRow,
  EventCount
FROM
  tmp_orders_sessions_update_ntile
WHERE
  Ntile != 1;

-- Join the first & second halves of the odd-numbered set:
CREATE TEMP TABLE tmp_orders_sessions_assign_row_number_odd AS
SELECT * FROM
(
   WITH pre AS
    (
      SELECT
        OrderNumber,
        OrderDate,
        OrderDateTime,
        Email,
        BrowserGUID,
        EventSessionKey,
        SessionStartDate,
        SessionStartTime,
        StoreID,
        CampaignID,
        RowNumber,
        Ntile,
        NtileRow,
        EventCount
      FROM
        tmp_orders_sessions_assign_row_number_first_half
      UNION ALL
      SELECT
        OrderNumber,
        OrderDate,
        OrderDateTime,
        Email,
        BrowserGUID,
        EventSessionKey,
        SessionStartDate,
        SessionStartTime,
        StoreID,
        CampaignID,
        RowNumber,
        Ntile,
        NtileRow,
        EventCount
      FROM
        tmp_orders_sessions_assign_row_number_second_half
    )
SELECT
  OrderNumber,
  OrderDate,
  OrderDateTime,
  Email,
  BrowserGUID,
  EventSessionKey,
  SessionStartDate,
  SessionStartTime,
  StoreID,
  CampaignID,
  RowNumber,
  Ntile,
  NtileRow,
  EventCount
FROM
  pre
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
);


-- #### EVEN NUMBER EVENTS:
-- Set where num eventsessions is EVEN:
CREATE TEMP TABLE tmp_orders_sessions_assign_row_number_even AS
SELECT
  OrderNumber,
  OrderDate,
  OrderDateTime,
  Email,
  BrowserGUID,
  EventSessionKey,
  SessionStartDate,
  SessionStartTime,
  StoreID,
  CampaignID,
  RowNumber,
  Ntile,
  CASE WHEN Ntile = 1 THEN ROW_NUMBER() OVER (PARTITION BY OrderNumber, Ntile ORDER BY SessionStartTime DESC)
       ELSE ROW_NUMBER() OVER (PARTITION BY OrderNumber, Ntile ORDER BY SessionStartTime) END AS NtileRow,
  EventCount
FROM
  tmp_orders_sessions_count_events
WHERE
  (EventCount % 2) = 0;


-- #### JOIN odd & even event tables
CREATE TEMP TABLE tmp_orders_sessions_assign_row_number_join AS
SELECT
  OrderNumber,
  OrderDate,
  OrderDateTime,
  Email,
  BrowserGUID,
  EventSessionKey,
  SessionStartDate,
  SessionStartTime,
  StoreID,
  CampaignID,
  RowNumber,
  Ntile,
  NtileRow,
  EventCount
FROM
  tmp_orders_sessions_assign_row_number_odd
UNION ALL
SELECT
  OrderNumber,
  OrderDate,
  OrderDateTime,
  Email,
  BrowserGUID,
  EventSessionKey,
  SessionStartDate,
  SessionStartTime,
  StoreID,
  CampaignID,
  RowNumber,
  Ntile,
  NtileRow,
  EventCount
FROM
  tmp_orders_sessions_assign_row_number_even;


CREATE TEMP TABLE tmp_orders_sessions_ntile_squared AS
SELECT
  OrderNumber,
  OrderDate,
  OrderDateTime,
  Email,
  BrowserGUID,
  EventSessionKey,
  SessionStartDate,
  SessionStartTime,
  StoreID,
  CampaignID,
  RowNumber,
  Ntile,
  NtileRow,
  POWER(NtileRow, 2) AS NtileRowSq,
  SUM(POWER(NtileRow, 2)) OVER (PARTITION BY OrderNumber ORDER BY SessionStartTime ROWS UNBOUNDED PRECEDING) AS SumNtileRowSq
FROM
  tmp_orders_sessions_assign_row_number_join;


CREATE TEMP TABLE tbl_multi_click_attribution AS
SELECT
  OrderNumber,
  OrderDate,
  OrderDateTime,
  Email,
  BrowserGuid,
  EventSessionKey,
  SessionStartDate,
  SessionStartTime,
  StoreID,
  CampaignID,
  RowNumber,
  Ntile,
  NtileRow,
  NtileRowSq,
  SumNtileRowSq,
  NtileRowSq * (1.0 / LAST_VALUE(SumNtileRowSq) OVER (PARTITION BY OrderNumber ORDER BY SessionStartTime ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) AS Weight
FROM
  tmp_orders_sessions_ntile_squared;

--Timing
WHERE (DATE_TRUNC('day', CONVERT_TIMEZONE ('America/Los_Angeles', OrderDate)))
BETWEEN dateadd (day, -60, '{{ var("start_date",run_started_at.strftime("%Y-%m-%d"))}}')::date
AND dateadd (day, -1, '{{ var("end_date",run_started_at.strftime("%Y-%m-%d"))}}')::date
