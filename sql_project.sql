/* What is the genres' distribution? */
SELECT
  g.Name Genres,
  COUNT(t.trackid) num_tracks
FROM track t
JOIN Genre g
  ON t.GenreId = g.GenreId
GROUP BY 1
ORDER BY 2 DESC;


/* What is the most popular genre in each country? */
WITH c_purchase
AS (SELECT
  t.GenreId genres,
  SUM(il.Quantity) purchases,
  c.Country Country_name,
  g.Name genre_name
FROM Track t
JOIN Genre g
  ON g.GenreId = t.GenreId
JOIN InvoiceLine il
  ON t.TrackId = il.TrackId
JOIN Invoice i
  ON i.InvoiceId = il.InvoiceId
JOIN Customer c
  ON c.CustomerId = i.CustomerId
GROUP BY 1,3)

SELECT
  t1.max_purchase Purchases,
  t1.country Country,
  t2.genre_name Name,
  t2.genres GenreId
FROM (SELECT
  c_purchase.country_name country,
  MAX(c_purchase.purchases) max_purchase
FROM c_purchase
GROUP BY 1) t1
JOIN (SELECT
  Country_name,
  MAX(c_purchase.purchases) max_purchase,
  genre_name,
  genres
FROM c_purchase
GROUP BY 1,3) t2
  ON t1.country = t2.Country_name
  AND t1.max_purchase = t2.max_purchase
ORDER BY 2;

/* Top 10 cities where we made money the most */
SELECT
  c.city City,
  SUM(i.total) Total_spent
FROM Invoice i
JOIN Customer c
  ON c.CustomerId = i.CustomerId
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;


/* Who are the top 10 artists? */
SELECT
  art.Name Artist_Name,
  (SUM(il.quantity * il.UnitPrice)) Amount_Spent
FROM Artist art
JOIN Album a
  ON art.ArtistId = a.ArtistId
JOIN Track t
  ON a.AlbumId = t.AlbumId
JOIN InvoiceLine il
  ON il.TrackId = t.TrackId
GROUP BY 1
HAVING Amount_Spent
ORDER BY 2 DESC
LIMIT 10;


/* What are the top 10 songs in term of purchases? */
SELECT
  t.Name Track_name,
  COUNT(il.trackid) num_purchases,
  (SUM(il.quantity * il.UnitPrice)) AmountSpent
FROM InvoiceLine il
JOIN Track t
  ON t.TrackId = il.TrackId
GROUP BY 1
ORDER BY 2 DESC, 3 DESC
LIMIT 10;



/* What are the names of the customers who purchased the most in each country? */
WITH total_spent
AS (SELECT
  SUM(i.total) totalSpent,
  c.CustomerId customer,
  c.FirstName first,
  c.LastName last,
  c.Country Country
FROM Customer c
JOIN Invoice i
  ON c.CustomerId = i.CustomerId
GROUP BY 2,3,4,5)


SELECT
  max_spent.countries Country,
  max_spent.maxs "Total Spent",
  (total_spent.first || " " || total_spent.last) "Full Name"
FROM total_spent
JOIN (SELECT
  MAX(total_spent.totalSpent) maxs,
  total_spent.Country countries
FROM total_spent
GROUP BY 2) max_spent
  ON max_spent.maxs = total_spent.totalSpent
  AND total_spent.Country = max_spent.countries
ORDER BY 1;


/* Does long songs sell well? */
WITH long_songs
AS (SELECT
  Name
FROM Track
WHERE Milliseconds > (SELECT
  AVG(Milliseconds)
FROM Track)
ORDER BY 1 DESC),
Avg_spending
AS (SELECT
  AVG(t1.purchase)
FROM (SELECT
  (SUM(InvoiceLine.quantity * InvoiceLine.UnitPrice)) purchase,
  TrackId
FROM InvoiceLine
GROUP BY 2) t1)

SELECT
  ROUND(AVG(avgspent_long.AmountSpent), 2) Avg_spent,
  CASE
    WHEN (AVG(avgspent_long.AmountSpent) >= (SELECT
        *
      FROM Avg_spending)
      ) THEN "YES"
    ELSE "NO"
  END Higher_than_AvgSpent
FROM (SELECT
  longtracks_price.track_name Name,
  (SUM(longtracks_price.quant * longtracks_price.price)) AmountSpent
FROM (SELECT
  t.name track_name,
  il.TrackId Id,
  il.UnitPrice price,
  il.quantity quant,
  CASE
    WHEN (t.name IN (SELECT
        *
      FROM long_songs)
      ) THEN "yes"
    ELSE "no"
  END appeared
FROM InvoiceLine il
JOIN track t
  ON t.TrackId = il.TrackId
  AND appeared = "yes") longtracks_price
GROUP BY 1
ORDER BY 2 DESC) avgspent_long;
