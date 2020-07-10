# Created by Alex Levashov, https://levashov.biz 
# Magento API R experiments
# Create a special magento admin user in your Magento admin
# Give it access to the resources you need to handle through API
# write the username and password

# in new version added requests as a functions, simple wrappers over Magento 2 Rest API


require("jsonlite", "httr", "tidyverse")
library(jsonlite)
library(httr)
library(tidyverse)


# Magento admin user credentials in format below
# change them to yours, URL must be with trailing slash
# for making it open source moved to a separate file
# but you may just uncomment it and put your details instead
# It should include the data in the next format:
# urlbase <- "http://domain.com/"
# username <- "username"
# password <- "password"

source('mcredentials.R')

# loading my function to work with Magento from R
source('Rmagento2API-functions.R')


# get token and store in a variable, we'll need it in each request later
auth <- getm2authtoken (urlbase, username, password)

# universal search 


# example calls with universal search

# endpoint - no first slash and now question mark in url!
# searching invoices after specific date
endpoint <- "rest/V1/invoices"

# query, list object, invoices after Jan 1st 2020

myquery <- list("searchCriteria[filter_groups][0][filters][0][field]"="created_at",
                "searchCriteria[filter_groups][0][filters][0][value]"="2020-01-01 00:00:00",
                "searchCriteria[filter_groups][0][filters][0][condition_type]"="gt")


invoices <- getm2objects(urlbase = urlbase, endpoint = endpoint, query = myquery, auth=auth)
# print fist invoice data
print (invoices$items[1])

# Logical OR search. With % wildcard, searching for products having "Dress" and "Throw" in names

endpoint <- "rest/V1/products"
# using 0 in first and 1 in second search criteria group
myquery <- list("searchCriteria[filter_groups][0][filters][0][field]"="name",
                "searchCriteria[filter_groups][0][filters][0][value]"="%Bag%",
                "searchCriteria[filter_groups][0][filters][0][condition_type]"="like",
                "searchCriteria[filter_groups][0][filters][1][field]"="name",
                "searchCriteria[filter_groups][0][filters][1][value]"="%Tote%",
                "searchCriteria[filter_groups][0][filters][1][condition_type]"="like")

products <- getm2objects(urlbase = urlbase, endpoint = endpoint, query = myquery, auth=auth)
# check number of the results
products[["total_count"]]

# Logical AND search, note change in filter_group filters 0 instead of 1 in second search query 

endpoint <- "rest/V1/products"

myquery <- list("searchCriteria[filter_groups][0][filters][0][field]"="name",
                "searchCriteria[filter_groups][0][filters][0][value]"="%tote%",
                "searchCriteria[filter_groups][0][filters][0][condition_type]"="like",
                "searchCriteria[filter_groups][1][filters][0][field]"="price",
                "searchCriteria[filter_groups][1][filters][0][value]"="250",
                "searchCriteria[filter_groups][1][filters][0][condition_type]"="lt")

products <- getm2objects(urlbase = urlbase, endpoint = endpoint, query = myquery, auth=auth)

# check number of the results
products[["total_count"]]


# Filtered responses

# filtered data for one specific product, only SKU, price and name


# test call, NB - no spaces in fields!

product <- getm2productdata (url=urlbase, sku="24-MB01", fields="sku,price,name,type_id", auth=auth)
# print what we got
product


#More Complex sample tasks
########
# sample tasks 1 - get names and emails of all customers who have placed no orders in given period of time

start_date <- "2020-05-01 00:00:00"
end_date <- "2020-05-31 23:59:59"

# step 1 - get all orders in the required period of time

endpoint <- "rest/V1/orders"

myquery <- list("searchCriteria[filter_groups][0][filters][0][field]"="created_at",
                "searchCriteria[filter_groups][0][filters][0][value]"=start_date,
                "searchCriteria[filter_groups][0][filters][0][condition_type]"="gt",
                "searchCriteria[filter_groups][1][filters][0][field]"="created_at",
                "searchCriteria[filter_groups][1][filters][0][value]"=end_date,
                "searchCriteria[filter_groups][1][filters][0][condition_type]"="lt")

orders <- getm2objects(urlbase = urlbase, endpoint = endpoint, query = myquery, auth=auth)
# check the number of the results we found

orders[["total_count"]]

# step 2 

# get emails of the customers who made that orders
# note - I've tried to use internal customer IDs instead, but for some reasons it didn't work in search call used later


# initialize empty factor and add there ids of customers who placed orders
customers_ordered <- character()

for (i in 1:length(orders[["items"]])){
        customers_ordered[i] <- orders[["items"]][[i]][["customer_email"]]
}


# inspect values
customers_ordered
# get rid of duplicates and combine in one string
customers_ordered <- unique(customers_ordered)

# step 3. Get customers who are not in this list

# form to query
customers_ordered_req <- paste(customers_ordered, collapse = ',')


# get all who not in the list of customers ordered
# using customer search endpoint

endpoint <- "rest/V1/customers/search/"

myquery <- list("searchCriteria[filter_groups][0][filters][0][field]"="email",
                "searchCriteria[filter_groups][0][filters][0][value]"=customers_ordered_req,
                "searchCriteria[filter_groups][0][filters][0][condition_type]"="nin")
cust_no <- getm2objects(urlbase = urlbase, endpoint = endpoint, query = myquery, auth=auth)

# Step 4. Save results for further use
# extract emails, first and last names to dataframe and cave to csv
emails_list <- data.frame()[1:length(cust_no[["items"]]),]
for (i in 1:length(cust_no[["items"]])) {
        emails_list$email[i] <- cust_no[["items"]][[i]][["email"]]
        emails_list$fname[i] <-  cust_no[["items"]][[i]][["firstname"]]
        emails_list$lname[i] <- cust_no[["items"]][[i]][["lastname"]]
}
# write as CSV file to use in your email software
row.names(emails_list) <-NULL
write.csv(emails_list, file="email-list.csv", row.names = FALSE)

