use sakila;

-- Step 1: get relevant information about films in our inventory
select f.film_id, f.title, c.name as genre, f.rental_rate, f.rating, 
i.store_id, count(i.inventory_id) as in_inventory 
from film f
join film_category l on f.film_id = l.film_id
join category c on l.category_id = c.category_id
join inventory i on f.film_id = i.film_id
group by f.film_id, i.store_id
order by f.film_id
;

-- Step 2: find metrics about the local popularity of the film
select f.film_id, i.store_id, count(r.rental_id) as film_local_rentals,
round(percent_rank() over (partition by i.store_id order by count(r.rental_id)), 2) as local_popularity_percentile,
max(r.rental_date) as film_last_rental
from rental r
join inventory i on i.inventory_id = r.inventory_id
join film f on i.film_id = f.film_id
group by i.film_id, i.store_id
order by f.film_id
;

-- Step 3: find metrics about the global popularity of the film
select f.film_id, count(r.rental_id) as film_global_rentals,
round(percent_rank() over (order by count(r.rental_id)), 2) as global_popularity_percentile
from rental r
join inventory i on i.inventory_id = r.inventory_id
join film f on i.film_id = f.film_id
group by i.film_id
order by f.film_id
;


-- Step 4: put everything in one query
with film_info as (
	select f.film_id, f.title, c.name as category, f.rental_rate, f.rating, 
	i.store_id, count(i.inventory_id) as in_inventory 
	from film f
	join film_category l on f.film_id = l.film_id
	join category c on l.category_id = c.category_id
	join inventory i on f.film_id = i.film_id
	group by f.film_id, i.store_id
	order by f.film_id
    )
select f.film_id, f.title, f.category, f.rental_rate, f.rating, f.store_id, f.in_inventory,
lr.film_local_rentals, lr.local_popularity_percentile, gr.film_global_rentals, gr.global_popularity_percentile, 
if(
	(year(lr.film_last_rental) = (select year(max(rental_date)) from rental))
	& (month(lr.film_last_rental) = (select month(max(rental_date)) from rental)), 
    True, False) as rent_last_month
from film_info as f
join (
	select f.film_id, i.store_id, count(r.rental_id) as film_local_rentals,
	round(percent_rank() over (partition by i.store_id order by count(r.rental_id)), 2) as local_popularity_percentile,
	max(r.rental_date) as film_last_rental
	from rental r
	join inventory i on i.inventory_id = r.inventory_id
	join film f on i.film_id = f.film_id
	group by i.film_id, i.store_id
	order by f.film_id
    )
    as lr
	on f.film_id = lr.film_id and f.store_id = lr.store_id
join (
	select f.film_id, count(r.rental_id) as film_global_rentals,
	round(percent_rank() over (order by count(r.rental_id)), 2) as global_popularity_percentile
	from rental r
	join inventory i on i.inventory_id = r.inventory_id
	join film f on i.film_id = f.film_id
	group by i.film_id
	order by f.film_id
	)
    as gr
    on f.film_id = gr.film_id
order by f.film_id
;