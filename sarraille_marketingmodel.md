## Mirror-Image, Reverse-Decay Model for Multi-Touch Marketing Attribution
### Claire Sarraille, Spring 2022

- Multi-touch marketing attribution is a technique used to weight specific marketing campaigns associated with customer sessions that lead to a purchase.
    - By multi-touch, we mean that we examine a series of User Sessions (or "touch points") associated that lead to a purchase.
    - Each Session is associated with a marketing campaign - e.g. A user clicks on an email to land on our ecommerce site.
    - Typically we think of the first session in time to be critical, as well as the session that occurs right before a purchase.
    - Sessions towards the middle of the series of sessions are viewed as having had less impact on the user's decision to make a purchase.
    - Rather than giving credit to a single marketing campaign for a given purchase, multi-touch models take into account several sessions leading up to a purchase.
- For this project, I demonstrate how to weight a 7-day history of user sessions leading to a purchase so that the first and last sessions are given the same weight, decaying exponentially to the middle session(s), which are weighted the least.
- To simplify the example, I will assign these generic digital marketing channels to each User Session without reference to specific campaigns.
    - (`'OrganicSearch', 'Direct', 'Social', 'PaidSearch', 'Email'`)
- In practice, marketing channels are simply a given medium (Email) used for a single marketing campaign (Christmas 2022 Email Blast).

#### Let's Start with 2 Separate Orders and 7 Days of User Session Data Preceding Each Order
- Our goal is to create a weight for each session per order, and to assign the least weight to the middle session(s).
- To simplify demonstrating the model, I created a toy data set with the following fields:
    - `OrderID`
    - `OrderDT` - Order Date and Time
    - `SessionID` - A unique identifyer for a time-bound bundle of user clicks, associated with a single `ChannelID`
    - `SessionDT` - Session Date and Time
    - `ChannelID`
- We are looking at these two orders and a 7-day window of User Sessions leading up to each.
- There are an ODD number (11 sessions) associated with order #123, and an EVEN number (10 sessions) associated with #456

#### Order #123
|		|	OrderID	|	OrderDT	    |	SessionID	|	SessionDT	|	ChannelID	 |
| :---  | :---      | :---          |  :---         | :---           | :---                |
|	1	|	123	    |6/10/22 19:00	|	ihg789	|	6/3/22 14:00	|	OrganicSearch|
|	2	|	123	|	6/10/22 19:00	|	lkj123	|	6/4/22 1:00	|	OrganicSearch	|
|	3	|	123	|	6/10/22 19:00	|	onm654	|	6/4/22 10:00	|	OrganicSearch	|
|	4	|	123	|	6/10/22 19:00	|	rqp789	|	6/4/22 10:30	|	Email	|
|	5	|	123	|	6/10/22 19:00	|	uts123	|	6/4/22 10:40	|	Email	|
|	6	|	123	|	6/10/22 19:00	|	xwv456	|	6/6/22 16:15	|	PaidSearch	|
|	7	|	123	|	6/10/22 19:00	|	zzy789	|	6/6/22 16:45	|	Direct	|
|	8	|	123	|	6/10/22 19:00	|	cba321	|	6/8/22 15:00	|	Social	|
|	9	|	123	|	6/10/22 19:00	|	fed654	|	6/9/22 8:00	|	OrganicSearch	|
|	10	|	123	|	6/10/22 19:00	|	ghi987	|	6/9/22 12:00	|	Email	|
|	11	|	123	|	6/10/22 19:00	|	fed456	|	6/10/22 18:45	|	PaidSearch	|


#### Order #456
|		|	OrderID	|	OrderDT	|	SessionID	|	SessionDT	|	ChannelID	|
|	:---	|	:---	|	:---	|	:---	|	:---	|	:---	|
|	1	|	456	|	7/5/22 13:00	|	abc123	|	6/28/22 11:25	|	OrganicSearch	|
|	2	|	456	|	7/5/22 13:00	|	def456	|	6/28/22 14:50	|	Social	|
|	3	|	456	|	7/5/22 13:00	|	ghi789	|	6/30/22 0:40	|	OrganicSearch	|
|	4	|	456	|	7/5/22 13:00	|	jkl123	|	7/1/22 8:10	|	PaidSearch	|
|	5	|	456	|	7/5/22 13:00	|	mno456	|	7/2/22 7:20	|	Direct	|
|	6	|	456	|	7/5/22 13:00	|	pqr789	|	7/4/22 20:00	|	Direct	|
|	7	|	456	|	7/5/22 13:00	|	stu123	|	7/4/22 20:30	|	Social	|
|	8	|	456	|	7/5/22 13:00	|	vwx456	|	7/4/22 20:45	|	PaidSearch	|
|	9	|	456	|	7/5/22 13:00	|	yzz789	|	7/4/22 21:35	|	PaidSearch	|
|	10	|	456	|	7/5/22 13:00	|	cba123	|	7/5/22 14:45	|	Email	|

#### Bifurcase Sessions per Order Using NTILE
- I bifurcate the sessions, partitioned by `OrderID` (ordered by `SessionStartTime`) into two groups using the `NTILE` function
- For each order, the first half of events are `NTILE` = 1, second half is `NTILE` = 2
    - In the case of an order having an odd-number of sessions associated with it, there will be slightly more sessions where `NTILE` = 1 versus `NTILE` = 2


|RowNumber|Ntile|NtileRow|
|:---|:---| :---|
|1|1|6|
|2|1|5|
|3|1|4|
|4|1|3|
|5|1|2|
|6|1|1|
|7|2|2|
|8|2|3|
|9|2|4|
|10|2|5|
|11|2|6|
```
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
ROW_NUMBER() OVER (PARTITION BY OrderNumber
    ORDER BY SessionStartTime) AS RowNumber,
    NTILE(2) OVER (PARTITION BY OrderNumber ORDER BY SessionStartTime) AS Ntile
FROM
tmp_all_visits_all_devices_67_days_ago
WHERE
SessionStartTime >= OrderDateTime - INTERVAL '7 days'
AND SessionStartTime <= OrderDateTime
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;
```

- Next I count `EventSessionKey` per Order using `LAST_VALUE` and partitioning by `OrderNumber`
```
LAST_VALUE ( RowNumber)
    OVER ( PARTITION BY OrderNumber
    ORDER BY SessionStartTime ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS EventCount
```

- From there I split the orders data into those with an odd and even number of events per order
    - For orders having ODD number of events: I re-assign the middle event (ordered by `SessionStartTime`) in the field `NTILE` to 3.
        - Now `NTILE` = 1 for the first half of the events, 3 for the middle event, and 2 for the second half of the events: `CASE WHEN RowNumber = EventCount / 2 + 1 THEN 3 ELSE Ntile END AS Ntile`

- Continuing with the odd group:
    - For each order number, assign a row number (Named it `NtileRow`) starting with the middle event (`NTILE` = 3) and ascending in both directions to the first and last events, respectively
    - For example, for an order that has eleven User Event Sessions (`EventSessionKey`), it would have these values for `NtileRow`

|EventID (ORDER BY SessionStartTime ASC)|NtileRow|
|:---|:---|
|1|6|
|2|5|
|3|4|
|4|3|
|5|2|
|6|1|
|7|2|
|8|3|
|9|4|
|10|5|
|11|6|

```
CASE WHEN Ntile = 1
OR Ntile = 3 THEN
ROW_NUMBER () OVER ( PARTITION BY ORDERNUMBER ORDER BY SessionStartTime DESC)
END AS NtileRow
```
```
CASE WHEN Ntile = 2
OR Ntile = 3 THEN
ROW_NUMBER () OVER ( PARTITION BY OrderNumber ORDER BY SessionStartTime)
END AS NtileRow
```

- Even Group:
    - Assigning an `NtileRow` value is much more straightforward
    - We assign the group where `Ntile` = 1 an `NtileRow` value by ordering `SessionStartTime` descending, and the Ntile = 2 group ordering `SessionStartTime` ascending
```
CASE WHEN Ntile = 1 THEN
ROW_NUMBER() OVER (PARTITION BY OrderNumber, Ntile ORDER BY SessionStartTime DESC)
ELSE
ROW_NUMBER() OVER (PARTITION BY OrderNumber, Ntile ORDER BY SessionStartTime)
END AS NtileRow
  ```

- The math:
    - I now have my field `NtileRow` that I can use to create a weight where the middle event is weighted the least, reverse decaying to the first and last events
    - First I square `NtileRow` and sum the squares partitioned by `OrderNumber`:
```
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
SUM(POWER(NtileRow, 2))
    OVER (PARTITION BY OrderNumber ORDER BY SessionStartTime ROWS UNBOUNDED PRECEDING)
    AS SumNtileRowSq
```

|EventID (ORDER BY SessionStartTime ASC)|NtileRow|NtileRowSq|SumNtileRowSq|
|:--- |:---   |:---  |:---|
|1|6  |36|36|
|2|5  |25|61|
|3|4  |16|77|
|4|3  |9|86|
|5|2  |4|90|
|6|1  |1|91|
|7|2  |4|95|
|8|3  |9|104|
|9|4  |16|120|
|10|5 |25|145|
|11|6 |36|181|

- Finally, we get our "parabola shaped" multi-click attribution model `weight` value
    - The formula is `NtileRowSq * (1.0 / Sum(NtileRowSq))` (The sum of `NtileRowSq` per order is the last value partitioned by `OrderNumber` in the `SumNtileRowSq` field:
    - This `weight` field was then available in our "Click-Stream" marketing model to evaluate the estimated impact of our marketing campaigns on purchases.
```
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
NtileRowSq * (1.0 / LAST_VALUE(SumNtileRowSq)
    OVER (PARTITION BY OrderNumber
    ORDER BY SessionStartTime
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) AS Weight
```

|	EventID	|	NtileRow	|	NtileRowSq	|	SumNtileRowSq	|	Weight	|
|:--|:--|:--|:--|:--|
|		|		|		|		|		|
|	1	|	6	|	36	|	36	|	0.198895028	|
|	2	|	5	|	25	|	61	|	0.138121547	|
|	3	|	4	|	16	|	77	|	0.08839779	|
|	4	|	3	|	9	|	86	|	0.049723757	|
|	5	|	2	|	4	|	90	|	0.022099448	|
|	6	|	1	|	1	|	91	|	0.005524862	|
|	7	|	2	|	4	|	95	|	0.022099448	|
|	8	|	3	|	9	|	104	|	0.049723757	|
|	9	|	4	|	16	|	120	|	0.08839779	|
|	10	|	5	|	25	|	145	|	0.138121547	|
|	11	|	6	|	36	|	181	|	0.198895028	|

- As you can see above, the middle User Event Session, where `EventID` = 6, has the least weight, and the weight symmetrically and exponentially increases.
    - Where there is an EVEN number of User Event Sessions per Order, we have two middle events with the same weight.

|	EventID	|	NtileRow	|	NtileRowSq	|	SumNtileRowSq	|	Weight	|
|:---	|	:---	|	:---	|	:---	|:---		|
|	1	|	6	|	36	|	36	|	0.2	|
|	2	|	5	|	25	|	61	|	0.138888889	|
|	3	|	4	|	16	|	77	|	0.088888889	|
|	4	|	3	|	9	|	86	|	0.05	|
|	5	|	2	|	4	|	90	|	0.022222222	|
|	6	|	2	|	4	|	94	|	0.022222222	|
|	7	|	3	|	9	|	103	|	0.05	|
|	8	|	4	|	16	|	119	|	0.088888889	|
|	9	|	5	|	25	|	144	|	0.138888889	|
|	10	|	6	|	36	|	180	|	0.2	|
