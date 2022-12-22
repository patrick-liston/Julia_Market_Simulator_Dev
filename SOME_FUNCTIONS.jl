#######################################################################################################
#######################################################################################################
### Imitiating Variables and Stuff for Tests - Can bassically skip this section for now.
#######################################################################################################
#######################################################################################################
#### All_orders table - used to keep track of each order that is placed. Is reffered back to when an order gets called/executed ####
#time_lodged[1], Order_id[2], order_type[3], order_price[4], order_trigger_price[5], order_amount[6], order_direction[7], order_amount_remaining[8]
#ORDER TYPES: 0-Market, 1-Limit, 2-SL
#ORDER DIRECTION: 0-B, 1-S
#time, agent_id, order_id, order_type, order_price, trigger_price , order_amount, order_direction, order_amount
all_orders=[
[[1,1,1,1,101,nothing,10,1,10]]
[[1,2,2,1,100,nothing,5,1,5]]
[[1,3,3,2,102,102,6,1,6]]
[[1,4,4,3,100,100,9,1,9]]
[[2,5,5,3,102,102,5,0,5]]
[[2,5,6,2,99,99,7,0,7]]
[[1,5,7,1,98,nothing,10,0,10]]
[[1,5,8,1,97,nothing,10,0,10]]
]

#### Seperate LOB into buy/sells book ###
#Buy/sell book follow the structure - [100 [1], 102, [3,5], 105, [2,4]...]
#With [price_lvel [order_id's]] - #BOTH books have price levels in ASCENDING order
buys_book=[]
sells_book=[]
#Stop-loss book follow same format as above
sl_buys=[]
sl_sells=[]

#### Executed trades - used to track which trades have been COMPLETED ###
#current_time[1], fill_price[2], amount_filled[3], fill_trade_id[4], order_id[5], filling_order_direction[6]
executed_trades=[]


### Agent info table - contains relevant information about agent parameters and account holdings ###
#agent_id[1], strat[2], params[3], account_holdings[4], account_holdings_2[5]
#Start - Can be different strategy types - currently just using "R" as a default for testing
#Params - list of relevant parameters which can are accessed when the agent is called to make a desicion
#Accounts_holdings - amount in "cash"
#Account_holdings_2 - amount in stock/coin/alternative currency
agent_info=[
[1, "R", [100], 1000, 500],
[2, "R", [10], 2000, 50],
[3, "R", [10], 2003, 55],
[4, "R", [10], 2001, 60],
[5, "R", [10], 2000, 40]
]
current_price=100 #Used as a intial price - so we can start the simulation process

## These are the buy/sell books transcribed/created from the "all_orders" table above - used for testing
sells_book=[100, [2], 101,[1]]
buys_book= [97, [8], 98, [7]]
tp_buys=[102,[5]]
sl_buys=[99,[6]]
sl_sells=[102, [3]]
tp_sells=[100, [4] ]



agent_id=1; order_direction=0; order_amount=40; ctime=1000
order_id=length(all_orders)+1; order_type=1; order_price=101; order_amount=40; order_direction=0; complete=0; ctime=0; trigger_price=nothing; agent_id=1
#new_order=market_order(all_orders, agent_id, order_direction, order_amount, ctime)
new_order=[ctime, agent_id, order_id, order_type, order_price, trigger_price , order_amount, order_direction, order_amount]


everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades, current_price];
print("\n",everything)
everything = place_order(new_order, everything, 45)
print("\n",everything)
all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades, current_price = get_everything(everything)


stop


#######################################################################################################
#######################################################################################################
### MAIN EXECUTION SECTION
#######################################################################################################
#######################################################################################################

function place_order(new_order, everything, current_time)
#all_orders, agent_info, buys_book, sells_book, tp_buys, tp_sells, sl_buys, sl_sells, executed_trades = get_everything(everything)
#Get all the order information
#order_time, order_agent_id, order_id, order_type, order_price, order_trigger, order_amount, order_direction, order_complete = get_order_info(new_order)
#Append the trade to all_orders if it is the first occurence
order_id=new_order[3]
order_type=new_order[4]
all_orders=everything[1]
if length(all_orders)+1==order_id; append!(all_orders, [new_order]); end



###################
#   STOP-LOSS ORDERS
###################
#If stop loss, put into sl book
if order_type==2
    all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades, current_price = get_everything(everything)
    #Check if there is ANY possibility of excuting the order - place into sl-book (if not triggering anything)
    #Place teat as if it is a normal order - execute like limit order?
    if order_direction==0 #Buy
        if order_id < length(all_orders) #This order was already put on - therefore, just now it has been triggered, so treat it like a limit-order
            everything=buy_order(new_order, everything, current_time) #Execute like a normal order
            return everything #buy_order(new_order, everything, current_time) #Execute like a normal order
        else #This is a new order - need to execute differently

            #There are sells - need to check if the order gets triggered
            if new_order[6]>=current_price
                #We have triggered the order - execute as a normal order
                everything=buy_order(new_order, everything, current_time) #Execute like a normal order
                return everything
            else
                #Did not trigger the order - place it into the stop loss book as required
                sl_buys=add_to_book(sl_buys, order_price, order_id)
                everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades, current_price];
                return everything; end; #If there are no sells - Can't be matched. Kill the order

            #end #Check if NEW order or OLD order
        end #Check if triggered or not
    end #End uy/sell direction check
end #End stop-loss order


###################
#   MARKET ORDERS
###################
#If market order - execute
if order_type==0   #Covers normal market orders - but what about stop-loss market orders?
    all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades, current_price = get_everything(everything)
    if order_direction==0 #Buy
        if isempty(sells_book); print("\nBUYNo orders to match with, kill the order"); return everything; end; #If there are no sells - Can't be matched. Kill the order
        return execute_market_buy(new_order, everything, current_time)

    else order_direction==1 #Sell
        print("\n\n\nBUYS BOOK: ", buys_book)
        if isempty(buys_book); print("\nSELLNo orders to match with, kill the order"); return everything; end; #If there are no buys - Can't be matched. Kill the order
        return execute_market_sell(new_order, everything, current_time)
    end #End order direction decision
end #end market order section

###################
#   Limit Orders
###################
#Note: I should prbably replace this sction with buy/sell order functions - although there MAY be a slight variation in their execution vs other order types

#If we have a limit order  - do X
if order_type==1 || order_type[1]==1
    #Determine if buy/sell - then execute accordingly
    if order_direction==0 #Buy
        print("this is a buy")
        if isempty(sells_book); buys_book=add_to_book(buys_book, order_price, order_id);
            everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades];
             return everything; end; #If there are no sells - we must place it in book - as it will not be matched

        #Else we need to check orders and stuff
        continue_executing=1
        #Otherwise - we need to check the buys_book to see if we can fill orders
        while all_orders[order_id][9]!=0 && continue_executing==1 && order_price>=first(sells_book)
            fill_trade_id=sells_book[2][1]; fill_price=first(sells_book)

            #1. Calculate amount filled
            amount_filled=ifelse(all_orders[fill_trade_id][9]>=all_orders[order_id][9], all_orders[order_id][9], all_orders[fill_trade_id][9])

            #2. Update all_orders table
            all_orders = update_all_orders(all_orders, fill_trade_id, order_id, amount_filled)

            #3. Remove order from sells_book - if filled
            if all_orders[fill_trade_id][9]==0; sells_book = remove_order(sells_book, 1, 1); end

            #4.Update executed orders table
            append!(executed_trades, [[current_time, fill_price, amount_filled, fill_trade_id, order_id, order_direction]])

            #5. Update agent_holdings positions
            print("\nBefore: ", agent_info)
            agent_info = update_agent_info(agent_info, fill_trade_id, agent_id, fill_price, amount_filled, order_direction )
            print("\nAfter: ", agent_info)

            #6. Check to see if sl/tp orders are triggered
            stopped_order_id=check_sl_tp(fill_price, all_orders, order_direction, sl_buys, sl_sells)
            print("\nStops to execute!", stopped_order_id)
            #Convert/Update the stop orders in all_orders to table (to enable execution)
            #all_orders[stopped_order_id][2]=ifelse(all_orders[stopped_order_id][4]==nothing, 0 , all_orders[stopped_order_id][2]+10)
            #Execute Stop order
            #place_trade(all_orders[stopped_order_id])


            # #7.check if sells_book is empty/if continue_executing still == 1
            # if isempty(sells_book); continue_executing=0; end #If there are no more buys in the book. Stop executing this loop. Put this here so we don't get reference errors for an empty list
            #7.check if sells_book is empty/if continue_executing still == 1 - If there is still "order" to execute, place it into BUYS book
            if isempty(sells_book); continue_executing=0; #Stop executing
                if all_orders[order_id][9]!=0; buys_book=add_to_book(buys_book, order_price, order_id); end #Add the order into the sells book
                    everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades]; return everything;
             end #If there are no more buys in the book. Stop executing this loop. Put this here so we don't get reference errors for an empty list

            #8. Output "Everything"
            everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades]
            return everything
        end #End while loop


        #Determine if buy/sell - then execute accordingly
        elseif order_direction==1 #Sell
            if isempty(buys_book); sells_book=add_to_book(sells_book, order_price, order_id);
                everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades];
                 return everything; end; #If there are no sells - we must place it in book - as it will not be matched

            #Else we need to check orders and stuff
            continue_executing=1
            #Otherwise - we need to check the buys_book to see if we can fill orders
            while all_orders[order_id][9]!=0 && continue_executing==1 && order_price<=buys_book[end-1]
                fill_trade_id=last(buys_book)[1]; fill_price=buys_book[end-1]

                #1. Calculate amount filled
                amount_filled=ifelse(all_orders[fill_trade_id][9]>=all_orders[order_id][9], all_orders[order_id][9], all_orders[fill_trade_id][9])

                #2. Update all_orders table
                all_orders = update_all_orders(all_orders, fill_trade_id, order_id, amount_filled)

                #3. Remove order from buys_book - if filled
                if all_orders[fill_trade_id][9]==0; buys_book = remove_order(buys_book, length(buys_book)-1, 1); end

                #4.Update executed orders table
                append!(executed_trades, [[current_time, fill_price, amount_filled, fill_trade_id, order_id, order_direction]])

                #5. Update agent_holdings positions
                print("\nBefore: ", agent_info)
                agent_info = update_agent_info(agent_info, fill_trade_id, agent_id, fill_price, amount_filled, order_direction )
                print("\nAfter: ", agent_info)

                #6. Check to see if sl/tp orders are triggered
                stopped_order_id=check_sl_tp(fill_price, all_orders, order_direction, sl_buys, sl_sells)
                print("\nStops to execute!", stopped_order_id)
                #Execute Stop order
                #place_trade(all_orders[stopped_order_id])


                #7.check if sells_book is empty/if continue_executing still == 1 - If there is still "order" to execute, place it into BUYS book
                if isempty(buys_book); continue_executing=0; #Stop executing
                    if all_orders[order_id][9]!=0; sells_book=add_to_book(sells_book, order_price, order_id); end #Add the order into the sells book
                        everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades]; return everything;
                    end #If there are no more buys in the book. Stop executing this loop. Put this here so we don't get reference errors for an empty list


                #8. Output "Everything"
                everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades]
                return everything
                end #End while loop
            end #End the BUY/SELL if/else for Limit orders
        end #End order type - limit order
end #Place order function


#######################################################################################################
#######################################################################################################
###                                HELPER FUNCTIONS                                                 ###
#######################################################################################################
#######################################################################################################
#### NOTE we need an "update_agent_posistion" - function, for after each trade execution ####

### Function to generate Market Orders ###
function market_order(all_orders, agent_id, order_direction, order_amount, ctime)
    if order_direction==0
        return new_order=[ctime, agent_id, length(all_orders)+1, 0, 1000000000, nothing , order_amount, order_direction, order_amount]
    else
        return new_order=[ctime, agent_id, length(all_orders)+1, 0, -1000000000, nothing , order_amount, order_direction, order_amount]
    end #End if else for order direction
end #End function



##########################################################################
##### USED TO DETERMINE WHICH STOP-LOSS ORDER SHOULD BE EXECUTED NEXT ####
##########################################################################
#There are two functions here because I am in the process of removing Take-Profit orders (F1 is the old version which I KNOW works, F2 needs testing)

#Check which order from Take-profits and/or Stop-Losses to fill
function check_sl_tp(fill_price, all_orders, order_direction, tp_buys, tp_sells, sl_buys, sl_sells)
    print("tp_buys: ",tp_buys, " tp_sells: ", tp_sells, " sl_buys: ", sl_buys, " sl_sells: ", sl_sells)
trigger_execute=[]
if order_direction==0
    if isempty(sl_buys)==false ; if fill_price>=sl_buys[1]; append!(trigger_execute,sl_buys[2][1]); end; end
    if isempty(tp_sells)==false; if fill_price>=tp_sells[1];  append!(trigger_execute,tp_sells[2][1]); end; end
    #Ensure the less expensive stop is hit first
    if length(trigger_execute)>1; if tp_sells[1]!=sl_buys[1]; if tp_sells[1]<sl_buys[1]; return trigger_execute[2]; else; return  trigger_execute[1]; end; end; end
else
    if isempty(tp_buys)==false ; if fill_price<=tp_buys[end-1][1]; append!(trigger_execute,tp_buys[end][1]); end; end
    if isempty(sl_sells)==false; if fill_price<=sl_sells[end-1][1];  append!(trigger_execute,sl_sells[end][1]); end; end; end
    #Ensure the more expensive stop is hit first
    if length(trigger_execute)>1; if sl_sells[end-1]!=tp_buys[end-1]; if sl_sells[end-1]>tp_buys[end-1]; return trigger_execute[2]; else; return  trigger_execute[1]; end; end; end
if length(trigger_execute)==0; return; end #If there are no orders to execute; return nothing
#IF SAME PRICE: Determine which order was lodged first - therefore, which we will execute first
if length(trigger_execute)>1;  if all_orders[trigger_execute[1]][1]<all_orders[trigger_execute[2]][1]; return trigger_execute[1]; else return trigger_execute[2]; end; else; trigger_execute[1]; end
end



#Check which order from Take-profits and/or Stop-Losses to fill
function check_sl_tp(fill_price, all_orders, order_direction, sl_buys, sl_sells)
    print(" sl_buys: ", sl_buys, " sl_sells: ", sl_sells)
trigger_execute=[]
if order_direction==0
    if isempty(sl_buys)==false ; if fill_price>=sl_buys[1]; append!(trigger_execute,sl_buys[2][1]); end; end
    #Ensure the less expensive stop is hit first
    if length(trigger_execute)>0;  return trigger_execute[2]; else; return  trigger_execute[1]; end; end; end
else
    if isempty(sl_sells)==false; if fill_price<=sl_sells[end-1][1];  append!(trigger_execute,sl_sells[end][1]); end; end; end
    #Ensure the more expensive stop is hit first
    if length(trigger_execute)>1; if sl_sells[end-1]!=tp_buys[end-1]; if sl_sells[end-1]>tp_buys[end-1]; return trigger_execute[2]; else; return  trigger_execute[1]; end; end; end
if length(trigger_execute)==0; return; end #If there are no orders to execute; return nothing
#IF SAME PRICE: Determine which order was lodged first - therefore, which we will execute first
if length(trigger_execute)>1;  if all_orders[trigger_execute[1]][1]<all_orders[trigger_execute[2]][1]; return trigger_execute[1]; else return trigger_execute[2]; end; else; trigger_execute[1]; end
end




##########################################################################
##### YPDATING AGENT INFOR MATINO AND STUFF ####
##########################################################################

#Function to update agent_holdings #
#agent_info = update_agent_info(agent_info, fill_trade_id, order_agent_id, fill_price, amount_filled, order_direction )
function update_agent_info(agent_info, fill_trade_id, order_agent_id, fill_price, amount_filled, order_direction )
    fill_trade_agent_id=all_orders[fill_trade_id][2] #Get filled trade agent id
    #Buy==1, order_agent BUYS the stock/coin, giving CASH to fill_trade_agent
    if order_direction==1
        agent_info[fill_trade_agent_id][4]+=amount_filled*fill_price; agent_info[fill_trade_agent_id][5]-=amount_filled #Increase Cash, Decrease stock - of fill agent
        agent_info[order_agent_id][4]     -=amount_filled*fill_price; agent_info[order_agent_id][5]+=amount_filled #Decrease Cash, Increase stock - of new_order agent
    else
        agent_info[fill_trade_agent_id][4]-=amount_filled*fill_price; agent_info[fill_trade_agent_id][5]+=amount_filled #Decrease Cash, Increase stock - of fill agent
        agent_info[order_agent_id][4]     +=amount_filled*fill_price; agent_info[order_agent_id][5]-=amount_filled #Increase Cash, Decrease stock - of new_order agent
    end
    return agent_info
end



##########################################################################
##### FUNCTIONS TO LOOK FOR ORDER LEVELS AND UPDATE EXECUTED TRADE STUFF ####
##########################################################################

#Function to update amount_remaining in all_orders table - needed for tracking when orders are complete #
function update_all_orders(all_orders, fill_trade_id, order_id, amount_filled)
    all_orders[fill_trade_id][9]-=amount_filled
    all_orders[order_id][9]-=amount_filled
    return all_orders
end



#Finds an orders price level and location within the levels' list - i.e Find the orders location within the book #
function find_order(book, price, order_id)
#Find location of price
idx=findall(isequal(price), book)
#Find location of order_id
if length(idx)>0; id=findall(isequal(order_id), book[idx[1]+1]); return idx[1], id else return 0,0; end
#If we have an index - delete it and update the all_orders table
if length(id)>0; return idx[1], id[1] else return idx[1],0 ; end
end



#Function to remove orders from the orderbook - using book and location as input, optionally location_2 #
#NOTE when using this function to delete first/last entry, i/e buy/sell
#remove_order(book, 1, nothing); remove_order(book, length(book)-1, nothing)
function remove_order(book, location, location_2)
    #If there are many orders at the price level - Check is there is another location/order_id specified
        #If there is no additonal location specified, then we remove the first placed order, otherwise we remove the specified order
    #If there is only one order at the price level, remove the price level and the associated order
    if length(book[location+1])>1;
        if isnothing(location_2)== false; deleteat!(book[location+1],location_2); return book
        else deleteat!(book[location+1],1); return book; end
    else; deleteat!(book, location); deleteat!(book, location); return book ; end
end




### Add the order into the correct order book, in the correct location ###
function add_to_book(book,order_price, order_id)
    if isnothing(book)||length(book)<1; append!(book, order_price); append!(book, [[order_id]]); return book; end #Nothing in book - just add it in
    #Find correct index. If it exists, place the orer_id in the right location. Else, add in price level then also the order_id
    idx,exist=find_order_level(book, order_price)
    if exist==1; append!(book[idx+1], order_id); return book
    else; insert!(book,idx, order_price);  insert!(book,idx+1, [order_id]); return book; end
end




#Find the location of where the order SHOULD be placed, and echecks if it exists#
#Usage - if searching for order existence, returns LOC[idx] & 1-if exists/ 0-if not exist
function find_order_level(book, order_price)
    if isnothing(book)==true||length(book)<1; return 1,0; end #No entries in book - put at start
    if length(book)==2; if order_price>first(book); return 3,0; elseif order_price==first(book); return 1,1; else return 1,0 end; end #Only one entry in book - check if given price is above/below/same
    i=1; book_length=length(book)-3
    while order_price>book[i] && order_price>=book[i+2] && i<book_length;  i+=2;    end
    #print("\nOrder price: ", order_price, " Book price: ", book[i], " i: ", i)
    if i==book_length; if order_price>book[i+2]; return i+4,0; elseif order_price==book[i+2]; return i+2,1; else return i+2,0; end; end #Dealing with indexs at the end of the book
    if order_price==book[i]; return i,1; end #This index exists, and is where the order should go
    if order_price<book[i]; return i,0 ;end #Order price in location, but level doesn't exist
    if order_price>book[i]; return i+2,0 ;end #Orer location is higher than index
end



#Function to CANCEL an order ####
function cancel_order(all_orders, book, price, order_id)
    location, location_2 = find_order(book, price, order_id)
    if location_2!=0; book= remove_order(book, location, location_2);  all_orders[order_id][8]=nothing; end
    return all_orders, book
end



##########################################################################
##### RANDOM FUNCTION TO "SIMPLIFY" CODE WRITING AND HELP READABILITY ####
##########################################################################

#Function to take "everything" and then seperate it - useful during Dev. to clean the code up a litte
function get_everything(everything)
    all_orders=everything[1]
    agent_info=everything[2]
    buys_book=everything[3]
    sells_book=everything[4]
    sl_buys=everything[5]
    sl_sells=everything[6]
    executed_trades=everything[7]
    current_price=everything[8]
    return all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades, current_price
end


#order_time, order_agent_id, order_id, order_type, order_price, order_trigger, order_amount, order_direction, order_complete = get_order_info(new_order)
#### Order_id[1], order_type[2], order_price[3], order_amount[4], order_direction[5] ####
#ORDER TYPES: 0-Market, 1-Limit, 2-SL, 3-TP, 12-SL-execute, 13-TO-execute #ORDER DIRECTION: 0-B, 1-S
function get_order_info(new_order)
    order_time=new_order[1]
    order_agent_id=new_order[2]
    order_id=new_order[3]
    order_type=new_order[4]
    order_price=new_order[5]
    order_trigger=new_order[6]
    order_amount=new_order[7]
    order_direction=new_order[8]
    order_complete=new_order[9]
return order_time, order_agent_id, order_id, order_type, order_price, order_trigger, order_amount, order_direction, order_complete
end


# Faster function to get relevant info for order execution ##
function get_order_info_quicker(new_order)
    order_id=new_order[3]
    order_price=new_order[5]
    order_direction=new_order[8]
return order_id, order_price, order_direction
end
















##########################################################################
##### TEMPLATE FOR "BUY" ORDERS - THIS SHOULD PROBS BUT USED MORE ####
##########################################################################
#This function SHOULD serve as a base for BUY executions - but at this stage it still needs work to ensure it functions properly
#Also need to see if it can integrate into all 3 cases: 1- Limit Orders, 2- Market orders, 3- EXECUTING stop-loss orders

function buy_order(new_order, everything, current_time)
#Get all the prep stuff we need
all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades, current_price = get_everything(everything)
order_id, order_price, order_direction = get_order_info_quicker(new_order)
fill_price=current_price #Required for local scope vriable


if isempty(sells_book); buys_book=add_to_book(buys_book, order_price, order_id);
    everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades];
     return everything; end; #If there are no sells - we must place it in book - as it will not be matched

#Else we need to check orders and stuff
continue_executing=1
#Otherwise - we need to check the buys_book to see if we can fill orders
while all_orders[order_id][9]!=0 && continue_executing==1 && order_price>=first(sells_book)
    fill_trade_id=sells_book[2][1]; fill_price=first(sells_book)

    #1. Calculate amount filled
    amount_filled=ifelse(all_orders[fill_trade_id][9]>=all_orders[order_id][9], all_orders[order_id][9], all_orders[fill_trade_id][9])

    #2. Update all_orders table
    all_orders = update_all_orders(all_orders, fill_trade_id, order_id, amount_filled)

    #3. Remove order from sells_book - if filled
    if all_orders[fill_trade_id][9]==0; sells_book = remove_order(sells_book, 1, 1); end

    #4.Update executed orders table
    append!(executed_trades, [[current_time, fill_price, amount_filled, fill_trade_id, order_id, order_direction]])

    #5. Update agent_holdings positions
    agent_info = update_agent_info(agent_info, fill_trade_id, agent_id, fill_price, amount_filled, order_direction )

    #6. Check to see if sl/tp orders are triggered
    stopped_order_id=check_sl_tp(fill_price, all_orders, order_direction, sl_buys, sl_sells)
    sl_buys, sl_sells = remove_sl_order(stopped_order_id, sl_buys, sl_sells)
    if  stopped_order_id>0;
        everything = place_order(all_orders[stopped_order_id], everything, 45);  #45 is standing in for "cucrent_time" while testing
    end
    #Convert/Update the stop orders in all_orders to table (to enable execution)
    #all_orders[stopped_order_id][2]=ifelse(all_orders[stopped_order_id][4]==nothing, 0 , all_orders[stopped_order_id][2]+10)
    #Execute Stop order
    #place_trade(all_orders[stopped_order_id])


    # #7.check if sells_book is empty/if continue_executing still == 1
    # if isempty(sells_book); continue_executing=0; end #If there are no more buys in the book. Stop executing this loop. Put this here so we don't get reference errors for an empty list
    #7.check if sells_book is empty/if continue_executing still == 1 - If there is still "order" to execute, place it into BUYS book
    if isempty(sells_book); continue_executing=0; #Stop executing
        if all_orders[order_id][9]!=0; buys_book=add_to_book(buys_book, order_price, order_id); end #Add the order into the sells book
            everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades,fill_price]; return everything;
     end #If there are no more buys in the book. Stop executing this loop. Put this here so we don't get reference errors for an empty list

end #End while loop
    #Coulnd't fill ANY order - append into book, and return everything
    if all_orders[order_id][9]!=0; buys_book=add_to_book(buys_book, order_price, order_id); end #Add the order into the sells book

    #8. Output "Everything"
    everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades, fill_price]
    return everything



end #End the function




##########################################################################
##### Find and remove stop-los order from stop-loss order book ####
##########################################################################
function remove_sl_order(order_id, sl_buys, sl_sells)
    if isempty(sl_sells)==false; if order_id==first(last(sl_sells)); sl_sells= remove_order(sl_sells, length(sl_sells)-1, 1); return sl_buys, sl_sells; end ;end
    if isempty(sl_buys)==false;  if order_id==sl_buys[2][1];         sl_buys= remove_order(sl_buys, 1, 1);                    return sl_buys, sl_sells; end ;end
    return sl_buys, sl_sells
end
#DOING SOME TESTS OF THE STOP-LOSS REMOVAL
stopped_order_id=check_sl_tp(99, all_orders, order_direction,  sl_buys, sl_sells)
print("\nStopped_loss_order: ", stopped_order_id, "    sl_buys after: ", sl_buys)
sl_buys, sl_sells = remove_sl_order(order_id, sl_buys, sl_sells)




















#######################################################################################################
#######################################################################################################
###                                  MARKET ORDERS                                                  ###
#######################################################################################################
#######################################################################################################
#These orders have some repeated code and should be simplified

###### FOR MARKET ORDER FUNCTION     #######
function execute_market_sell(new_order, everything, current_time)
#Else we need to check orders and stuff
continue_executing=1;
all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades, current_price = get_everything(everything)
order_id, order_price, order_direction = get_order_info_quicker(new_order)
fill_price=current_price #Required for local scope vriable
#Otherwise - we need to check the buys_book to see if we can fill orders
while all_orders[order_id][9]!=0 && continue_executing==1 && order_price<=buys_book[end-1]
    fill_trade_id=last(buys_book)[1]; fill_price=buys_book[end-1]

    #1. Calculate amount filled
    amount_filled=ifelse(all_orders[fill_trade_id][9]>=all_orders[order_id][9], all_orders[order_id][9], all_orders[fill_trade_id][9])

    #2. Update all_orders table
    all_orders = update_all_orders(all_orders, fill_trade_id, order_id, amount_filled)

    #3. Remove order from buys_book - if filled
    if all_orders[fill_trade_id][9]==0; buys_book = remove_order(buys_book, length(buys_book)-1, 1); end

    #4.Update executed orders table
    append!(executed_trades, [[current_time, fill_price, amount_filled, fill_trade_id, order_id, order_direction]])

    #5. Update agent_holdings positions
    agent_info = update_agent_info(agent_info, fill_trade_id, agent_id, fill_price, amount_filled, order_direction )

    #7.check if sells_book is empty/if continue_executing still == 1 - If there is still "order" to execute, place it into BUYS book
    if isempty(buys_book); continue_executing=0; end #Stop executing

end #End while loop
##### after fully executing the market order then we will implelment this check
#6. Check to see if sl/tp orders are triggered
stopped_order_id=check_sl_tp(fill_price, all_orders, order_direction,  sl_buys, sl_sells)

#8. Output "Everything"
everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades, fill_price]
return everything
end



###### FOR MARKET ORDER FUNCTION     #######
function execute_market_buy(new_order, everything, current_time)
#Else we need to check orders and stuff
continue_executing=1;
all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades, current_price = get_everything(everything)
order_id, order_price, order_direction = get_order_info_quicker(new_order)
fill_price=current_price #Required for local scope vriable

#Otherwise - we need to check the buys_book to see if we can fill orders
while all_orders[order_id][9]!=0 && continue_executing==1 && order_price>=first(sells_book)
    fill_trade_id=sells_book[2][1]; fill_price=first(sells_book)

    #1. Calculate amount filled
    amount_filled=ifelse(all_orders[fill_trade_id][9]>=all_orders[order_id][9], all_orders[order_id][9], all_orders[fill_trade_id][9])

    #2. Update all_orders table
    all_orders = update_all_orders(all_orders, fill_trade_id, order_id, amount_filled)

    #3. Remove order from sells_book - if filled
    if all_orders[fill_trade_id][9]==0; sells_book = remove_order(sells_book, 1, 1); end

    #4.Update executed orders table
    append!(executed_trades, [[current_time, fill_price, amount_filled, fill_trade_id, order_id, order_direction]])

    #5. Update agent_holdings positions
    agent_info = update_agent_info(agent_info, fill_trade_id, agent_id, fill_price, amount_filled, order_direction )

    #7.check if sells_book is empty/if continue_executing still == 1 - If there is still "order" to execute, too bad - it just gets left because we can't fill it
    if isempty(sells_book); continue_executing=0; end #Stop executing

end #End while loop
##### after fully executing the market order then we will implelment this check

#6. Check to see if sl/tp orders are triggered
stopped_order_id=check_sl_tp(fill_price, all_orders, order_direction, sl_buys, sl_sells)

#8. Output "Everything"
everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades, fill_price]
return everything
end

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
    
##########################################################################
#####        BUY ORDER       ####
##########################################################################
#Get all the prep stuff we need
function buy_order()
all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades, current_price = get_everything(everything)
order_id, order_price, order_direction = get_order_info_quicker(new_order)
fill_price=current_price #Required for local scope vriable


#If there are no sells - we must place it in book - as it will not be matched
if isempty(sells_book); buys_book=add_to_book(buys_book, order_price, order_id); everything[3]=buys_book; return everything ; end

#### MAIN EXECUTION SECTION ####
continue_executing=1
#Otherwise - we need to check the buys_book to see if we can fill orders
while all_orders[order_id][9]!=0 && continue_executing==1 && order_price>=first(sells_book)
    fill_trade_id=sells_book[2][1]; fill_price=first(sells_book)

    #1. Calculate amount filled
    amount_filled=ifelse(all_orders[fill_trade_id][9]>=all_orders[order_id][9], all_orders[order_id][9], all_orders[fill_trade_id][9])

    #2. Update all_orders table
    all_orders = update_all_orders(all_orders, fill_trade_id, order_id, amount_filled)

    #3. Remove order from sells_book - if filled
    if all_orders[fill_trade_id][9]==0; sells_book = remove_order(sells_book, 1, 1); end

    #4.Update executed orders table
    append!(executed_trades, [[current_time, fill_price, amount_filled, fill_trade_id, order_id, order_direction]])

    #5. Update agent_holdings positions
    agent_info = update_agent_info(agent_info, fill_trade_id, agent_id, fill_price, amount_filled, order_direction )

    # #6. Check to see if sl/tp orders are triggered
    # stopped_order_id=check_sl_tp(fill_price, all_orders, order_direction, sl_buys, sl_sells)
    # sl_buys, sl_sells = remove_sl_order(stopped_order_id, sl_buys, sl_sells)
    # if  stopped_order_id>0;
    #     everything = place_order(all_orders[stopped_order_id], everything, 45);  #45 is standing in for "cucrent_time" while testing
    # end
    # #Convert/Update the stop orders in all_orders to table (to enable execution)
    # #all_orders[stopped_order_id][2]=ifelse(all_orders[stopped_order_id][4]==nothing, 0 , all_orders[stopped_order_id][2]+10)
    # #Execute Stop order
    # #place_trade(all_orders[stopped_order_id])


    # #6.check if sells_book is empty/if continue_executing still == 1
    # if isempty(sells_book); continue_executing=0; end #If there are no more buys in the book. Stop executing this loop. Put this here so we don't get reference errors for an empty list
    #7.check if sells_book is empty/if continue_executing still == 1 - If there is still "order" to execute, place it into BUYS book
    if isempty(sells_book); continue_executing=0; #Stop executing
        if all_orders[order_id][9]!=0; buys_book=add_to_book(buys_book, order_price, order_id); end #Add the order into the sells book
            everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades,fill_price]; return everything;
     end #If there are no more buys in the book. Stop executing this loop. Put this here so we don't get reference errors for an empty list

end #End while loop
    #IF THIS IS A MARKET ORDER ORDER DON'T ADD THIS TO THE BOOK  - For now we will just keep the all_orders section the same (Otherwise it is more complicated - but mainly I don't see any real benifit to changing the all orders book to reflect that the order was not fully filled but would get ignored form now on)
    #Coulnd't fill ANY order - append into book, and return everything
    if all_orders[order_id][9]!=0 && new_order[4]!=0 ; buys_book=add_to_book(buys_book, order_price, order_id); end #Add the order into the sells book


    #8. Output "Everything"
    everything=[all_orders, agent_info, buys_book, sells_book, sl_buys, sl_sells, executed_trades, fill_price]
    return everything

end #End the function


        
        
        
        
        
