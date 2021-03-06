# Functions

# --- !Ups

-- create balances associated with currencies
create or replace function
currency_insert (
  a_position integer,
  a_currency varchar(16),
  a_country varchar(4),
  a_admin_g1 bigint,
  a_admin_l1 bigint
) returns void as $$
declare
begin
  insert into currencies (position, currency, country, admin_g1, admin_l1) values (a_position, a_currency, a_country, a_admin_g1, a_admin_l1);;
end;;
$$ language plpgsql volatile security definer set search_path = public, pg_temp cost 100;


create or replace function
insert_as_admin (
  a_country varchar(4),
  a_email varchar(256),
  a_user_country varchar(4),
  a_glo_n varchar(8)
) returns void as $$
declare
  b_user_id bigint;;
begin
  select id into b_user_id from users where email = a_email and country = a_user_country;;
  if a_glo_n = 'admin_g1' then
    update currencies set admin_g1 = b_user_id where country = a_country;;
  end if;;
  if a_glo_n = 'admin_g2' then
    update currencies set admin_g2 = b_user_id where country = a_country;;
  end if;;
  if a_glo_n = 'admin_l1' then
    update currencies set admin_l1 = b_user_id where country = a_country;;
  end if;;
  if a_glo_n = 'admin_l2' then
    update currencies set admin_l2 = b_user_id where country = a_country;;
  end if;;
  if a_glo_n = 'admin_o1' then
    update currencies set admin_o1 = b_user_id where country = a_country;;
  end if;;
  if a_glo_n = 'admin_o2' then
    update currencies set admin_o2 = b_user_id where country = a_country;;
  end if;;
end;;
$$ language plpgsql volatile security definer set search_path = public, pg_temp cost 100;


create or replace function
save_admins (
  a_country varchar(4),
  a_email_g1 varchar(256),
  a_email_g2 varchar(256),
  a_email_l1 varchar(256),
  a_email_l2 varchar(256),
  a_email_o1 varchar(256),
  a_email_o2 varchar(256),
  a_user_country_g1 varchar(4),
  a_user_country_g2 varchar(4),
  a_user_country_l1 varchar(4),
  a_user_country_l2 varchar(4),
  a_user_country_o1 varchar(4),
  a_user_country_o2 varchar(4)
) returns void as $$
declare
  b_id_g1 bigint;;
  b_id_g2 bigint;;
  b_id_l1 bigint;;
  b_id_l2 bigint;;
  b_id_o1 bigint;;
  b_id_o2 bigint;;
begin
  b_id_g1 = 0;;
  b_id_g2 = 0;;
  b_id_l1 = 0;;
  b_id_l2 = 0;;
  b_id_o1 = 0;;
  b_id_o2 = 0;;
--  select exists(select 1 from users where email = a_email_g1) as "exists";;
  if a_email_g1 != '' and a_email_l1 != '' then    
    select id into b_id_g1 from users where email = a_email_g1 and user_country = a_user_country_g1;;
    if a_email_g2 != '' then select id into b_id_g2 from users where email = a_email_g2 and user_country = a_user_country_g2;; end if;;
    select id into b_id_l1 from users where email = a_email_l1 and user_country = a_user_country_l1;;
    if a_email_l2 != '' then select id into b_id_l2 from users where email = a_email_l2 and user_country = a_user_country_l2;; end if;;
    if a_email_o1 != '' then select id into b_id_o1 from users where email = a_email_o1 and user_country = a_user_country_o1;; end if;;
    if a_email_o2 != '' then select id into b_id_o2 from users where email = a_email_o2 and user_country = a_user_country_o2;; end if;;

    update currencies set admin_g1 = b_id_g1, admin_g2 = b_id_g2, admin_l1 = b_id_l1, admin_l2 = b_id_l2, admin_o1 = b_id_o1, admin_o2 = b_id_o2 where country = a_country;;
  else
-- would return an error
  end if;;
end;;
$$ language plpgsql volatile security definer set search_path = public, pg_temp cost 100;


create or replace function
management_data (
    a_user_id bigint,
  out country_code varchar(4),
  out currency varchar(16),
  out number_users bigint,
  out fiat_funds numeric(23,8),
  out crypto_funds numeric(23,8),
  out system_balance numeric(23,8),
  out number_pending_orders bigint
) returns setof record as $$
declare
  b_currency varchar(16);;
  b_country varchar(4);;
begin

return query
  select c.country, c.currency,
       (select count(*) from users u where u.user_country = c.country),
       (select sum(b.balance) from balances b where b.currency = c.currency and b.user_id != 0),
       (select sum(b.balance_c) from balances b where b.currency = c.currency and b.user_id != 0),
       (select b.balance_c from balances b where b.currency = c.currency and user_id = 0),
       (select count(*) from orders o where o.country_id = c.country and (status = 'Op' or status = 'Lk'))
  from currencies c
  where (admin_g1 = a_user_id or admin_g2 = a_user_id or admin_l1 = a_user_id or admin_l2 = a_user_id)
  group by c.country, c.currency;;
end;;
$$ language plpgsql stable security definer set search_path = public, pg_temp cost 100;


create or replace function
create_order (
  a_user_id bigint,
  a_country_id varchar(4),
  a_order_type varchar(4),
  a_status varchar(2),
  a_partner varchar(128),
  a_currency varchar(16),
  a_initial_value numeric(23,8),
  a_local_fee numeric(23,8),
  a_global_fee numeric(23,8),
  a_bank varchar(128),
  a_agency varchar(16),
  a_account varchar(64),
  a_doc1 varchar(128),
  a_image_id bigint default 0
) returns boolean as $$
declare
  b_order_id bigint;;
  b_total_fee numeric(23,8);;
  b_partner_id bigint;;
  b_local_admin_id bigint;;
  b_global_admin_id bigint;;
begin
-- Create orders
  b_total_fee = a_local_fee + a_global_fee;;
  insert into orders (user_id, country_id, order_type, status, partner, currency, initial_value, total_fee, bank, agency, account, doc1, image_id) values (a_user_id, a_country_id, a_order_type, a_status, a_partner, a_currency, a_initial_value, b_total_fee, a_bank, a_agency, a_account, a_doc1, a_image_id) returning order_id into b_order_id;;
  select admin_g1, admin_l1 into b_global_admin_id, b_local_admin_id from currencies where currencies.country = a_country_id;;
  if (a_partner = '') then
    b_partner_id = 0;;  -- System account (used for convertions to Crypto and back to Fiat
  else
    select id into b_partner_id from users where email = a_partner;;
  end if;;

  if a_order_type = 'V' then
    -- if one order for that document already exists, user replaced document, must consider only the last one. Old orders become Rj with system information
    update orders set status = 'Rj', comment = '***** User replaced doc before analysis *****' where order_type = 'V' and partner = a_partner and status = 'Op' and partner = a_partner and user_id = a_user_id and order_id != b_order_id;;
    update users set docs_verified = false where id = a_user_id;;
    if a_partner = 'doc1' then update users_name_info set ver1 = false where user_id = a_user_id;; end if;;
    if a_partner = 'doc2' then update users_name_info set ver2 = false where user_id = a_user_id;; end if;;
    if a_partner = 'doc3' then update users_name_info set ver3 = false where user_id = a_user_id;; end if;;
    if a_partner = 'doc4' then update users_name_info set ver4 = false where user_id = a_user_id;; end if;;
    if a_partner = 'doc5' then update users_name_info set ver5 = false where user_id = a_user_id;; end if;;


  end if;;
-- for deposit and withdraw fees should be charged when order update and at send when sending. To fiat when order creation
  if a_order_type = 'D' or a_order_type = 'DS' or a_order_type = 'DCS' then
    update balances set balance = balance + a_initial_value, hold = hold + a_initial_value where currency = a_currency and user_id = a_user_id;;
    if a_order_type = 'DS' or a_order_type = 'DCS' then
      update users set partner = a_partner where id = a_user_id;;
      update users_connections set partner = a_partner, partner_account = a_account where user_id = a_user_id;;
    end if;;
  end if;;
  if a_order_type = 'W' or a_order_type = 'W.' then
    update balances set hold = hold + a_initial_value + b_total_fee where currency = a_currency and user_id = a_user_id;;
    update users_connections set bank = a_bank, agency = a_agency, account = a_account where user_id = a_user_id;;
  end if;;

  if a_order_type = 'C' then
    update balances set balance = balance - a_initial_value, balance_c = balance_c + a_initial_value where currency = a_currency and user_id = a_user_id;;
    update balances set balance = balance + a_initial_value, balance_c = balance_c - a_initial_value where currency = a_currency and user_id = b_partner_id;; -- Partner account
    update orders set status = 'OK', closed = current_timestamp, processed_by = b_partner_id, net_value = a_initial_value, comment = '***** System-processed Order *****' where order_id = b_order_id;;
  end if;;
  if a_order_type = 'S' or a_order_type = 'S.' then
  -- This creates a communication to partner system. Fees will be charged when order update (closing) 'S' is direct send and 'S.' is sending crypto currency ###
  end if;;
  if a_order_type = 'F' then
    update balances set balance = balance + a_initial_value - b_total_fee, balance_c = balance_c - a_initial_value where currency = a_currency and user_id = a_user_id;;
    update balances set balance = balance - a_initial_value, balance_c = balance_c + a_initial_value where currency = a_currency and user_id = b_partner_id;; -- Partner account
    update balances set balance = balance + a_local_fee where currency = a_currency and user_id = b_local_admin_id;; -- Local administrator account
    update balances set balance = balance + a_global_fee where currency = a_currency and user_id = b_global_admin_id;; -- Global administrator account
    update orders set status = 'OK', closed = current_timestamp, processed_by = b_partner_id, net_value = a_initial_value - b_total_fee, comment = '***** System-processed Order *****' where order_id = b_order_id;;
  end if;;
  if a_order_type = 'RFW' or a_order_type = 'RFW.' then
  -- ###
  end if;;
  if a_order_type = 'RW' or a_order_type = 'RW.' then
  -- ###
  end if;;
  return true;;

end;;
$$ language plpgsql volatile security definer set search_path = public, pg_temp cost 100;


-- This function updates orders, updates balance fiat, updates balance crypto, updates system balances (fees)
create or replace function
update_order (
  a_order_id bigint,
  a_status varchar(2),
  a_processed_value numeric(23,8),
  a_comment varchar(128),
  a_local_fee numeric(23,8),
  a_global_fee numeric(23,8),
  a_admin_id bigint
) returns boolean as $$
declare
  b_user_id bigint;;
  b_country varchar(4);;
  b_order_type varchar(4);;
  b_order_status varchar(2);;
  b_currency varchar(16);;
  b_initial_value numeric(23,8);;
  b_net_value numeric(23,8);;
  b_total_fee numeric(23,8);;
  b_update_fees boolean;;
  b_partner varchar(128);;
  b_ver1 boolean;;
  b_ver2 boolean;;
  b_ver3 boolean;;
  b_ver4 boolean;;
  b_ver5 boolean;;
  b_first_name varchar(64);;
  b_last_name varchar(128);;
  b_partner_id bigint;;
  b_local_admin_id bigint;;
  b_global_admin_id bigint;;
begin
-- Update orders and balances and user records (if V)
  select user_id, order_type, country_id, status, currency, initial_value, partner, total_fee into b_user_id, b_order_type, b_country, b_order_status, b_currency, b_initial_value, b_partner, b_total_fee
    from orders where order_id = a_order_id;;
  select admin_g1, admin_l1 into b_global_admin_id, b_local_admin_id from currencies where currencies.country = b_country;;

  if (b_partner = '') then
    b_partner_id = 0;;  -- System account (used for convertions to Crypto and back to Fiat
  else
    select id into b_partner_id from users where email = b_partner;;
  end if;;

  b_update_fees = false;;
-- At this point starts Order approved
  if a_status = 'OK' then
    if b_order_type = 'V' then
      update orders set status = 'OK', closed = current_timestamp, processed_by = a_admin_id, comment = a_comment where order_id = a_order_id;;
      if b_partner = 'doc1' then update users_name_info set ver1 = true where user_id = b_user_id;; end if;;
      if b_partner = 'doc2' then update users_name_info set ver2 = true where user_id = b_user_id;; end if;;
      if b_partner = 'doc3' then update users_name_info set ver3 = true where user_id = b_user_id;; end if;;
      if b_partner = 'doc4' then update users_name_info set ver4 = true where user_id = b_user_id;; end if;;
      if b_partner = 'doc5' then update users_name_info set ver5 = true where user_id = b_user_id;; end if;;
      select first_name, last_name, ver1, ver2, ver3, ver4, ver5 into b_first_name, b_last_name, b_ver1, b_ver2, b_ver3, b_ver4, b_ver5 from users_name_info where user_id = b_user_id;;
      if b_first_name != '' and b_last_name != '' and b_ver1 and b_ver2 and b_ver3 and b_ver4 and b_ver5 then
        update users set docs_verified = true where id = b_user_id;;
      end if;;
    end if;;
-- fees should be charged for deposit and withdraw when order update and at send when sending and to fiat when order creation
    if b_order_type = 'D' then
      if b_order_status = 'Op' then
        update balances set balance = balance - b_initial_value + a_processed_value - a_global_fee - a_local_fee, hold = hold - b_initial_value where currency = b_currency and user_id = b_user_id;;
        update orders set status = 'OK', closed = current_timestamp, processed_by = a_admin_id, net_value = a_processed_value, comment = a_comment where order_id = a_order_id;;
        b_update_fees = true;;
      else
    -- Order already processed (maybe by another administrator) ###
      end if;;
    end if;;
    if b_order_type = 'DS' or b_order_type = 'DCS' or b_order_type = 'S.' or b_order_type = 'S' then
      if b_order_status = 'Op' then
        if b_order_type = 'DS' then
          -- deposit approval
          update balances set balance = balance - b_initial_value + a_processed_value, hold = hold - b_initial_value + a_processed_value where currency = b_currency and user_id = b_partner_id;; -- Partner account
          update orders set status = 'S', closed = current_timestamp, processed_by = a_admin_id, net_value = a_processed_value, comment = a_comment where order_id = a_order_id;;
        else
          -- deposit approval and convertion done in one single step
          update balances set balance = balance - b_initial_value, hold = hold - b_initial_value, balance_c = balance_c + a_processed_value, hold_c = hold_c + a_processed_value where currency = b_currency and user_id = b_user_id;;
          update balances set balance = balance + a_processed_value, balance_c = balance_c - a_processed_value where currency = b_currency and user_id = b_partner_id;; -- Partner account
          update orders set status = 'S', closed = current_timestamp, processed_by = a_admin_id, net_value = a_processed_value, comment = a_comment where order_id = a_order_id;;
        end if;;
      else
        if b_order_type = 'DCS' or b_order_type = 'S.' then
        -- Sending crypto process just happened (sent only processed value minus fees, discounted outside this function, when sending) ###
          update balances set balance_c = balance_c - a_processed_value, hold_c = hold_c - a_processed_value where currency = b_currency and user_id = b_user_id;;
          update balances set balance = balance + a_processed_value - a_global_fee - a_local_fee, hold = hold - a_processed_value where currency = b_currency and user_id = b_partner_id;; -- Partner account
          update orders set status = 'OK', closed = current_timestamp, processed_by = a_admin_id, net_value = a_processed_value - a_global_fee - a_local_fee, comment = a_comment where order_id = a_order_id;;
          b_update_fees = true;;
        else
         if b_order_type = 'DS' or b_order_type = 'S' then
          -- Sending fiat process just happened (sent only processed value minus fees, discounted outside this function, when sending) ###
            update balances set balance = balance - a_processed_value, hold = hold - a_processed_value where currency = b_currency and user_id = b_user_id;;
            update balances set balance = balance + a_processed_value - a_global_fee - a_local_fee, hold = hold - a_processed_value where currency = b_currency and user_id = b_partner_id;; -- Partner account
            update orders set status = 'OK', closed = current_timestamp, processed_by = a_admin_id, net_value = a_processed_value - a_global_fee - a_local_fee, comment = a_comment where order_id = a_order_id;;
            b_update_fees = true;;
          else
          -- Order already processed (maybe by another administrator) ###
          end if;;
        end if;;
      end if;;
    end if;;

    if b_order_type = 'W' or b_order_type = 'W.' or b_order_type = 'RW' or b_order_type = 'RW.' or b_order_type = 'RFW' or b_order_type = 'RFW.' then
      if b_order_status = 'R' then
      -- ### receiving money from partner
      end if;;

      if b_order_status = 'F' then
        update balances set balance = balance + b_initial_value, balance_c = balance_c - b_initial_value where currency = b_currency and user_id = b_user_id;;
        update balances set balance = balance - b_initial_value, balance_c = balance_c + b_initial_value where currency = b_currency and user_id = b_partner_id;; -- Partner account
        update orders set status = 'Op', closed = current_timestamp, processed_by = a_admin_id, net_value = a_processed_value, comment = a_comment where order_id = a_order_id;;
      end if;;

      if b_order_status = 'Op' then
        update orders set status = 'Lk', closed = current_timestamp, processed_by = a_admin_id, net_value = a_processed_value, comment = a_comment where order_id = a_order_id;;
      else
        if b_order_status = 'Lk' then
        -- this part should not happen, as closing a withdraw order is done with picture update as well (update_order_with_picture)
        -- but this code is still enabled to OK without picture (if future changes).
          update balances set balance = balance - a_processed_value - a_global_fee - a_local_fee, hold = hold - b_initial_value - a_global_fee - a_local_fee where currency = b_currency and user_id = b_user_id;;
          update orders set status = 'OK', closed = current_timestamp, processed_by = a_admin_id, net_value = a_processed_value, comment = a_comment where order_id = a_order_id;;
          b_update_fees = true;;
        else
    -- Order already processed (maybe by another administrator) ###
        end if;;
      end if;;
    end if;;

    if b_order_type = 'RW' or b_order_type = 'RW.' or b_order_type = 'RFW' or b_order_type = 'RFW.' then
-- ###
    end if;;
    if b_update_fees then
--update balances set balance = balance + a_local_fee where currency = b_currency and user_id = 0;; -- test
      update balances set balance = balance + a_local_fee where currency = b_currency and user_id = b_local_admin_id;; -- Local administrator account
      update balances set balance = balance + a_global_fee where currency = b_currency and user_id = b_global_admin_id;; -- Global administrator account
    end if;;
    return true;;
  end if;;



-- After this point is order accepted with changes
  if a_status = 'Ch' then
    if b_order_type = 'D' or b_order_type = 'DCS' then
      if b_order_status = 'Op' then
        update balances set balance = balance - b_initial_value + a_processed_value - a_local_fee - a_global_fee, hold = hold - b_initial_value where currency = b_currency and user_id = b_user_id;;
        update orders set status = 'Ch', closed = current_timestamp, processed_by = a_admin_id, net_value = a_processed_value, total_fee = a_local_fee + a_global_fee, comment = a_comment where order_id = a_order_id;;

        update balances set balance = balance + a_local_fee where currency = b_currency and user_id = b_local_admin_id;; -- Local administrator account
        update balances set balance = balance + a_global_fee where currency = b_currency and user_id = b_global_admin_id;; -- Global administrator account
      end if;;
    end if;;
    if b_order_type = 'W' or b_order_type = 'W.' or b_order_type = 'RFW' or b_order_type = 'RFW.' then
      if b_order_status = 'Op' then
        update orders set status = 'Lk', closed = current_timestamp, processed_by = a_admin_id, net_value = a_processed_value, comment = a_comment where order_id = a_order_id;;
      end if;;
    end if;;
  end if;;

 -- After this point is order rejection
  if a_status = 'Rj' then
    if b_order_type = 'V' then
--    update orders set status = 'OK', closed = current_timestamp, processed_by = a_admin_id, comment = a_comment where order_id = a_order_id;;
      update orders set status = 'Rj', closed = current_timestamp, processed_by = a_admin_id, comment = a_comment where status = 'Op' and order_id = a_order_id;;
    end if;;
    if b_order_type = 'D' or b_order_type = 'DCS' then
      if b_order_status = 'Op' then
        update balances set balance = balance - b_initial_value, hold = hold - b_initial_value where currency = b_currency and user_id = b_user_id;;
        update orders set status = 'Rj', closed = current_timestamp, processed_by = a_admin_id, net_value = 0, total_fee = 0, comment = a_comment where order_id = a_order_id;;
      end if;;
    end if;;
    if b_order_type = 'W' or b_order_type = 'W.' then
      if b_order_status = 'Op' or b_order_status = 'Lk' then
        update balances set hold = hold - b_initial_value - b_total_fee where currency = b_currency and user_id = b_user_id;;
        update orders set status = 'Rj', closed = current_timestamp, processed_by = a_admin_id, net_value = 0, comment = a_comment where order_id = a_order_id;;
      end if;;
    end if;;

    if b_order_type = 'RFW' or b_order_type = 'RFW.' then
-- ###
    end if;;
  end if;;

--    update balances set balance = balance + a_net_value
--    where currency = (select currency FROM orders where order_id = a_order_id)
--    and user_id = (select user_id FROM orders where order_id = a_order_id);;

  return true;;
end;;
$$ language plpgsql volatile security definer set search_path = public, pg_temp cost 100;


-- This function updates orders, updates balance fiat, updates balance crypto, updates system balances (fees) when withdraw approval/rejection
create or replace function
update_order_with_picture (
  a_order_id bigint,
  a_order_type varchar(4),
  a_status varchar(2),
  a_processed_value numeric(23,8),
  a_local_fee numeric(23,8),
  a_global_fee numeric(23,8),
  a_comment varchar(128),
  a_image_id bigint,
  a_admin_id bigint
) returns boolean as $$
declare
  b_user_id bigint;;
  b_country varchar(4);;
  b_order_status text;;
  b_currency varchar(16);;
  b_initial_value numeric(23,8);;
  b_total_fee numeric(23,8);;
  b_global_fee numeric(23,8);;
  b_partner_id bigint;;
  b_local_admin_id bigint;;
  b_global_admin_id bigint;;
begin
  b_partner_id = 0;;

  select user_id, country_id, status, currency, initial_value, total_fee into b_user_id, b_country, b_order_status, b_currency, b_initial_value, b_total_fee from orders where order_id = a_order_id;;
  select admin_g1, admin_l1 into b_global_admin_id, b_local_admin_id from currencies where currencies.country = b_country;;

  b_global_fee = b_total_fee - a_local_fee;; -- to avoid rounding errors, care with total_fee and balances on hold
  if a_status = 'OK' or a_status = 'Ch' then
    if a_status = 'OK' then -- ### need to test a range of 0.02 difference (@globals.settings(securesocial.core.SecureSocial.currentUser.get.user_country, "minimum_difference)
      update balances set balance = balance - a_processed_value - a_global_fee - a_local_fee, hold = hold - b_initial_value - b_total_fee where currency = b_currency and user_id = b_user_id;;
      update orders set status = 'OK', closed = current_timestamp, processed_by = a_admin_id, net_value = a_processed_value, total_fee = a_local_fee + a_global_fee, comment = a_comment, image_id = a_image_id where order_id = a_order_id and status = 'Lk';;
    end if;;
    if a_status = 'Ch' then
      update balances set balance = balance - a_processed_value - a_global_fee - a_local_fee, hold = hold - b_initial_value - b_total_fee where currency = b_currency and user_id = b_user_id;;
      update orders set status = 'Ch', closed = current_timestamp, processed_by = a_admin_id, net_value = a_processed_value, total_fee = a_local_fee + a_global_fee, comment = a_comment, image_id = a_image_id where order_id = a_order_id and status = 'Lk';;
    end if;;
    update balances set balance = balance + a_local_fee where currency = b_currency and user_id = b_local_admin_id;; -- Local administrator account
    update balances set balance = balance + a_global_fee where currency = b_currency and user_id = b_global_admin_id;; -- Global administrator account
  end if;;

  if a_status = 'Rj' then
    update balances set hold = hold - b_initial_value - b_total_fee where currency = b_currency and user_id = b_user_id;;
    update orders set status = 'Rj', closed = current_timestamp, processed_by = a_admin_id, net_value = 0, total_fee = a_local_fee + a_global_fee, comment = a_comment, image_id = a_image_id where order_id = a_order_id and status = 'Lk';;
  end if;;
  return true;;
end;;
$$ language plpgsql volatile security definer set search_path = public, pg_temp cost 100;


create or replace function
update_personal_info (
  a_user_id bigint,
  a_first_name varchar(64),
  a_middle_name varchar(128),
  a_last_name varchar(128),
  a_doc1 varchar(256),
  a_doc2 varchar(256),
  a_doc3 varchar(256),
  a_doc4 varchar(256),
  a_doc5 varchar(256),
  a_bank varchar(16),
  a_agency varchar(16),
  a_account varchar(64),
  a_partner varchar(64),
  a_partner_account varchar(256),
  a_manualauto_mode bool
) returns boolean as $$
declare
begin
  update users_name_info set first_name = a_first_name, middle_name = a_middle_name, last_name = a_last_name, doc1 = a_doc1, doc2 = a_doc2, doc3 = a_doc3, doc4 = a_doc4, doc5 = a_doc5 where user_id = a_user_id;;
  update users_connections set bank = a_bank, agency = a_agency, account = a_account, partner = a_partner, partner_account = a_partner_account where user_id=a_user_id;;
  update users set manualauto_mode = a_manualauto_mode, partner = a_partner where id=a_user_id;;
  if a_first_name = '' or a_first_name = '' or a_doc1 = '' or a_doc2 = '' or a_doc3 = '' or a_doc4 = '' or a_doc5 = '' then
    update users set docs_verified = false where id = a_user_id;;
  else
    update users set docs_verified = true where id = a_user_id;;
  end if;;
  return true;;
end;;
$$ language plpgsql volatile security definer set search_path = public, pg_temp cost 100;


create or replace function
update_user_doc (
  a_user_id bigint,
  a_docNumber varchar(8),
  a_image_id bigint,
  a_fileName varchar(256)
) returns boolean as $$
begin
  if a_docNumber = 'doc1' then
    update users_name_info set doc1 = a_fileName, ver1 = false, pic1 = a_image_id where user_id = a_user_id;;
  end if;;
  if a_docNumber = 'doc2' then
    update users_name_info set doc2 = a_fileName, ver2 = false, pic2 = a_image_id where user_id = a_user_id;;
  end if;;
  if a_docNumber = 'doc3' then
    update users_name_info set doc3 = a_fileName, ver3 = false, pic3 = a_image_id where user_id = a_user_id;;
  end if;;
  if a_docNumber = 'doc4' then
    update users_name_info set doc4 = a_fileName, ver4 = false, pic4 = a_image_id where user_id = a_user_id;;
  end if;;
  if a_docNumber = 'doc5' then
    update users_name_info set doc5 = a_fileName, ver5 = false, pic5 = a_image_id where user_id = a_user_id;;
  end if;;
  update users set docs_verified = false where id = a_user_id;;
  return true;;
end;;
$$ language plpgsql volatile security definer set search_path = public, pg_temp cost 100;


create or replace function
update_bank_data (
  a_user_id bigint,
  a_bank varchar(16),
  a_agency varchar(16),
  a_account varchar(64)
) returns boolean as $$
begin
  update users_connections set bank = a_bank, agency = a_agency, account = a_account where user_id = a_user_id;;
  return true;;
end;;
$$ language plpgsql volatile security definer set search_path = public, pg_temp cost 100;


create or replace function
change_manualauto (
  a_id bigint,
  a_manualauto_mode bool
) returns boolean as $$
begin
  if a_id = 0 then
    raise 'User id 0 is not allowed to use this function.';;
  end if;;
  update users set manualauto_mode = a_manualauto_mode
  where id=a_id;;
  return true;;
end;;
$$ language plpgsql volatile security definer set search_path = public, pg_temp cost 100;

create or replace function
insert_user_image (
  a_name varchar(256),
  a_data bytea
) returns bigint as $$
declare
  b_image_id bigint;;
begin
  insert into image (name, data) values (a_name, a_data) returning image_id into strict b_image_id;;
  return b_image_id;;
end;;
$$ language plpgsql volatile security invoker set search_path = public, pg_temp cost 100;



# --- !Downs
drop function if exists insert_as_admin(varchar(4), varchar(256), varchar(4), varchar(8)) cascade;
drop function if exists currency_insert(integer, varchar(16), varchar(4)) cascade;
drop function if exists insert_admin(integer, varchar(16), varchar(4)) cascade;
drop function if exists create_order(Long, varchar(4), varchar(4), varchar(2), varchar(128)) cascade;
drop function if exists update_order(Long, varchar(2), numeric(23,8), varchar(128), numeric(23,8)) cascade;
drop function if exists update_order_with_picture(Long, varchar(2), numeric(23,8), varchar(128), numeric(23,8), numeric(23,8)) cascade;
drop function if exists update_personal_info(Long, varchar(64), varchar(128), varchar(128)) cascade;
drop function if exists update_user_doc(Long, varchar(8), Long, varchar(256)) cascade;
drop function if exists update_bank_data(Long, varchar(16), varchar(16), varchar(64)) cascade;
drop function if exists management_data(bigint) cascade;
drop function if exists change_manualauto(Long, bool) cascade;
drop function if exists insert_user_image (varchar(256), bytea) cascade;

-- security definer functions
