# Created by Alex Levashov, https://levashov.biz 
# Magento API R collection of functions
# simple wrappers over Magento 2 Rest API

require("jsonlite", "httr")
library(jsonlite)
library(httr)

# get auth token
# define authorisation as a function
# get token and store in a variable, to use in other requests
getm2authtoken <- function (url, username, password){
        myquery = list (username=username, password=password) 
        url <- paste0(urlbase, "index.php/rest/V1/integration/admin/token")
        myqueryj = toJSON(myquery, pretty = TRUE, auto_unbox = TRUE)
        req <- POST(url, add_headers ("Content-Type" = "application/json"),  body = myquery, encode = "json")
        token <-rawToChar(req$content[2:33])
        auth <- paste0("Bearer ", token)
        return (auth)
}

# universal search 

getm2objects <- function(urlbase, endpoint, query, auth){
        url <- paste0(urlbase, endpoint, "?")
        request <- GET(url, add_headers ("Content-Type" = "application/json", "Authorization" = auth), query = query)
        object <- content(request, as ="parsed")
        return (object)
}

# query sample below, should be a list with field, value, condition three-tuple in basic syntax
# myquery <- list("searchCriteria[filter_groups][0][filters][0][field]"="created_at",
#                 "searchCriteria[filter_groups][0][filters][0][value]"="2017-01-01 00:00:00",
#                 "searchCriteria[filter_groups][0][filters][0][condition_type]"="gt")

###
# more specific calls in separate functions
###

# search orders


getm2orders <- function (url, field, value, condition, auth){
        # changing API endpoint
        url <- paste0(url, "index.php/rest/V1/orders?")
        
        #making query
        myquery <- list("searchCriteria[filter_groups][0][filters][0][field]"=field,
                        "searchCriteria[filter_groups][0][filters][0][value]"=value,
                        "searchCriteria[filter_groups][0][filters][0][condition_type]"=condition)
        
        request <- GET(url, add_headers ("Content-Type" = "application/json", "Authorization" = auth), query = myquery)
        
        orders <- content(request, as ="parsed")
        return (orders)
}

# search products

getm2products <- function (url, field, value, condition, auth){
        # changing API endpoint
        url <- paste0(url, "index.php/rest/V1/products?")
        myquery <- list("searchCriteria[filter_groups][0][filters][0][field]"=field,
                        "searchCriteria[filter_groups][0][filters][0][value]"=value,
                        "searchCriteria[filter_groups][0][filters][0][condition_type]"=condition)
        
        request <- GET(url, add_headers ("Content-Type" = "application/json", "Authorization" = auth), query = myquery)
        products <- content(request, as = "parsed")
        return(products)
}


# Several specific functions with filtered responses

# filtered data for one specific product, only SKU, price and name
# parameters product in question sku and fields to return
getm2productdata <- function (url, sku, fields, auth){
        
        url <- paste0(urlbase, "index.php/rest/V1/products/", sku, "?fields=", fields)
        print (url)
        request <- GET (url, add_headers ("Content-Type" = "application/json", "Authorization" = auth))
        product <- content(request, as = "parsed")
        return (product)
}

# filtered (partial) customer details for specific order
# note that it uses not order id number seen in Magento admin or email receipt, 
# but order entity id, can be found if request order as in the above example

getm2customerdata <- function(url, order_id, fields, auth) {
        url <- paste0(urlbase, "/rest/default/V1/orders/", order_id, "?fields=", fields)
        request <- GET (url, add_headers ("Content-Type" = "application/json", "Authorization" = auth))
        customer <- content(request, as ="parsed")
        return (customer)
}

###

# Shipment data
# Top level object with selected fields 
# again it is internal entity it here

getm2shipmentdata <- function(url, shipment_id, fields, auth) {
        url <- paste0(url, "/rest/default/V1/shipment/", shipment_id, "?fields=", fields)
        request <- GET (url, add_headers ("Content-Type" = "application/json", "Authorization" = auth))
        shipment_data <- content(request, as ="parsed")
        return (shipment_data)        
} 

# customer data by customer id 

getm2customer_data <- function(url, customer_id, fields, auth) {
        url <- paste0(url, "rest/default/V1/customers/", customer_id, "?fields=", fields)
        url
        request <- GET (url, add_headers ("Content-Type" = "application/json", "Authorization" = auth))
        customer_data <- content(request, as ="parsed")
        return (customer_data)        
} 

