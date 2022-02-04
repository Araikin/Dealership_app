import psycopg2
from psycopg2.sql import SQL, Identifier, Literal

DB = "demo"
USER = "postgres"
HOST = "localhost"
PASSWORD = ""


def list_one_column(col, table):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/Common.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    cur.execute(SQL(sql_list[0]).format(Identifier(col), Identifier(table)))
    result = [x[0] for x in cur.fetchall()]
    cur.close()
    con.close()
    return result


def verify(username, password):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/Common.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    cur.execute(sql_list[2], (username,))
    result = cur.fetchone()[0] == password
    cur.close()
    con.close()
    return result


def check_usertype(username, usertype):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/Common.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    cur.execute(SQL(sql_list[1]).format(Identifier(usertype)))
    result = [x[0] for x in cur.fetchall()]
    cur.close()
    con.close()
    if username in result:
        return True
    return False


# ====================== ADD VEHICLE ==============================


def add_vehicle_db(manufacturer, vin, model_year, model_name, invoice_price, desc, date_added, username, colors,
                   vtype, has_back_door, doors_count, drivetrain_type, cupholders_count, roof_type,
                   back_seat_count, cover_type, rear_axles_count, cargo_capacity):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    insert_vehicle = False
    message = ""
    sql_file = open("sql/AddVehicle.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    cur.execute(sql_list[7], (vin,))
    result = cur.fetchone()
    if result:
        message = "Vehicle vin already exists"
    else:
        cur.execute(sql_list[0], (vin, manufacturer, model_name, model_year, invoice_price,
                                  desc, date_added, username, vin))
        if cur.rowcount == 1:
            if vtype == 'VanMinivan':
                cur.execute(sql_list[2], (vin, has_back_door))
            elif vtype == 'Car':
                cur.execute(sql_list[3], (vin, doors_count))
            elif vtype == 'SUV':
                cur.execute(sql_list[4], (vin, drivetrain_type, cupholders_count))
            elif vtype == 'Truck':
                cur.execute(sql_list[5], (vin, cargo_capacity, cover_type, rear_axles_count))
            elif vtype == 'Convertible':
                cur.execute(sql_list[6], (vin, roof_type, back_seat_count))
            if cur.rowcount == 1:
                if colors:
                    for color in colors:
                        cur.execute(sql_list[1], (vin, color))
                        if cur.rowcount == 1:
                            insert_vehicle = True
                        else:
                            insert_vehicle = False
                            break
        if insert_vehicle:
            con.commit()
        else:
            message = "Something went wrong with connection, try again"
    cur.close()
    con.close()
    return insert_vehicle, message


# ====================== VEHICLE DETAILS ==============================


def get_vehicle_details(vin, get_details):
    connection = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cursor = connection.cursor()
    sql_file = open("sql/VehicleDetails.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    if get_details:
        cursor.execute(SQL(sql_list[0]).format(Literal(vin)))
        result = cursor.fetchone()
    else:
        cursor.execute(sql_list[1], (vin,))
        result = cursor.fetchall()
    cursor.close()
    connection.close()
    return result


# ====================== VEHICLE SEARCH ==============================


def get_total_vehicle():
    connection = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cursor = connection.cursor()
    sql_file = open("sql/VehicleSearch.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    cursor.execute(SQL(sql_list[1]))
    results = cursor.fetchone()
    cursor.close()
    connection.close()
    return results[0]


def populate_dropdowns(col, table):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/VehicleSearch.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    cur.execute(SQL(sql_list[2]).format(Identifier(col), Identifier(table)))
    result = [x[0] for x in cur.fetchall()]
    cur.close()
    con.close()
    return result


def get_search_results(vin, vehicle_type, manufacturer, color, model_year, min_price, max_price, keyword, is_manager):
    connection = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cursor = connection.cursor()
    sql_file = open("sql/VehicleSearch.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    if is_manager:
        sql_query = SQL(sql_list[3]).format(Literal(keyword), Literal(keyword), Literal(keyword),
                                            Literal(vin), Literal(vin), Literal(vin),
                                            Literal(min_price), Literal(min_price),
                                            Literal(max_price), Literal(max_price),
                                            Literal(manufacturer), Literal(manufacturer), Literal(manufacturer),
                                            Literal(model_year), Literal(model_year), Literal(model_year),
                                            Literal(vehicle_type), Literal(vehicle_type), Literal(vehicle_type),
                                            Literal(keyword), Literal(keyword), Literal(keyword),
                                            Literal(keyword), Literal(keyword), Literal(keyword),
                                            Literal(color))
    else:
        sql_query = SQL(sql_list[0]).format(Literal(keyword), Literal(keyword), Literal(keyword),
                                            Literal(vin), Literal(vin), Literal(vin),
                                            Literal(min_price), Literal(min_price),
                                            Literal(max_price), Literal(max_price),
                                            Literal(manufacturer), Literal(manufacturer), Literal(manufacturer),
                                            Literal(model_year), Literal(model_year), Literal(model_year),
                                            Literal(vehicle_type), Literal(vehicle_type), Literal(vehicle_type),
                                            Literal(keyword), Literal(keyword), Literal(keyword),
                                            Literal(keyword), Literal(keyword), Literal(keyword),
                                            Literal(color))

    cursor.execute(sql_query)
    result = cursor.fetchall()
    cursor.close()
    connection.close()
    return result


# ====================== LOOKUP/ADD CUSTOMER ==============================


def get_customer_db(customer_type, id_no, customer_id):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/AddLookupCustomer.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    if customer_type and id_no:
        cur.execute(sql_list[2], (customer_type, id_no,))
    elif customer_id:
        cur.execute(sql_list[3], (customer_id,))
    result = cur.fetchall()
    cur.close()
    con.close()
    return result


def add_customer_db(ind, biz):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/AddLookupCustomer.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    if ind is not None:
        data = (ind[0], ind[1], ind[2], ind[3], ind[4], ind[5], ind[6], ind[6], ind[7], ind[8],)
        cur.execute(sql_list[0], data)
    elif biz is not None:
        data = (biz[0], biz[1], biz[2], biz[3], biz[4], biz[5], biz[6], biz[6], biz[7], biz[8], biz[9],)
        cur.execute(sql_list[1], data)
    result = cur.fetchone()
    con.commit()
    cur.close()
    con.close()
    return result


# ====================== SELL VEHICLE ==============================

# Revisit this later
def get_price(vin):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/SellVehicle.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    cur.execute(sql_list[0], (vin,))
    result = cur.fetchone()[0]
    cur.close()
    con.close()
    return result


def get_status(vin):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/SellVehicle.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    cur.execute(sql_list[1], (vin,))
    data = cur.fetchone()
    cur.close()
    con.close()
    if data:
        return 'Sold'
    return 'Available'


def sell_vehicle_db(vin, customer_id, username, sold_price, sold_date):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    success_flag = False
    sql_file = open("sql/SellVehicle.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    data = (vin, customer_id, username, sold_price, sold_date, vin, vin)
    cur.execute(sql_list[2], data)
    if cur.rowcount == 1:
        success_flag = True
    if success_flag:
        con.commit()
    cur.close()
    con.close()
    return success_flag


# ====================== REPAIRS ==============================


def get_repairs_info(vin, query):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/EnterRepair.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    result = None
    if query == "vehicle_info":
        cur.execute(sql_list[0], (vin,))
        result = cur.fetchone()
    elif query == "open_repair":
        cur.execute(sql_list[1], (vin,))
        result = cur.fetchone()
    cur.close()
    con.close()
    return result


def add_repair_db(vin, odometer, username, customer_id, start_date):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    success_flag = False
    sql_file = open("sql/EnterRepair.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    data = [start_date, vin, customer_id, username, odometer]
    cur.execute(sql_list[3], data)
    if cur.rowcount == 1:
        success_flag = True
    if success_flag:
        con.commit()
    cur.close()
    con.close()
    return success_flag


def update_repair_db(vin, labor_charges, description, start_date):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    success_flag = False
    sql_file = open("sql/EnterRepair.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    cur.execute(sql_list[4], (labor_charges, description, start_date, vin))
    if cur.rowcount == 1:
        success_flag = True
    if success_flag:
        con.commit()
    cur.close()
    con.close()
    return success_flag


def complete_repair_db(vin, start_date, end_date):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    success_flag = False
    sql_file = open("sql/EnterRepair.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    cur.execute(sql_list[8], (end_date, vin, start_date))
    if cur.rowcount == 1:
        success_flag = True
    if success_flag:
        con.commit()
    cur.close()
    con.close()
    return success_flag


def get_start_date(vin):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/EnterRepair.sql", "r")
    sql_list = sql_file.read().split(';')
    cur.execute(sql_list[6], (vin,))
    result = cur.fetchone()
    sql_file.close()
    cur.close()
    con.close()
    return result


def add_part_db(part_no, start_date, vin, vendor_name, price, quantity):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/EnterRepair.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    cur.execute(sql_list[7], (part_no, vendor_name))
    current_price = cur.fetchone()
    if current_price and float(current_price[0]) != float(price):
        cur.close()
        con.close()
        return False
    cur.execute(sql_list[5], (part_no, start_date, vin, vendor_name, price, quantity))
    if cur.rowcount == 1:
        con.commit()
        cur.close()
        con.close()
        return True
    cur.close()
    con.close()
    return False


def get_prev_data(vin):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/EnterRepair.sql", "r")
    sql_list = sql_file.read().split(';')
    cur.execute(sql_list[2], (vin,))
    result = cur.fetchone()
    sql_file.close()
    cur.close()
    con.close()
    return result


# ====================== REPORTS ==============================


def get_sales_by(report_type):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/Reports.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    sql_by_color = sql_list[0]
    sql_by_type = sql_list[1]
    sql_by_manufacturer = sql_list[2]
    if report_type == "color":
        cur.execute(sql_by_color)
    elif report_type == "type":
        cur.execute(sql_by_type)
    elif report_type == "manufacturer":
        cur.execute(sql_by_manufacturer)
    data = cur.fetchall()
    cur.close()
    con.close()
    return data


def get_gross_customer_income(customer_id):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/Reports.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    result = [None] * 3
    if customer_id is None:
        cur.execute(sql_list[3])
        result[0] = cur.fetchall()
    else:
        cur.execute(sql_list[4], (customer_id,))
        result[1] = cur.fetchall()
        cur.execute(sql_list[5], (customer_id,))
        result[2] = cur.fetchall()
    cur.close()
    con.close()
    return result


def get_repairs_by(manufacturer, vehicle_type):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/Reports.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    if manufacturer is None and vehicle_type is None:
        cur.execute(sql_list[6])
    elif manufacturer is not None and vehicle_type is None:
        cur.execute(sql_list[7], (manufacturer,))
    elif manufacturer is not None and vehicle_type is not None:
        cur.execute(sql_list[8], (manufacturer, vehicle_type,))
    result = cur.fetchall()
    cur.close()
    con.close()
    return result


def get_below_cost_sales():
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/Reports.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    cur.execute(sql_list[9])
    result = cur.fetchall()
    cur.close()
    con.close()
    return result


def get_avg_time_in_inventory():
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/Reports.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    cur.execute(sql_list[10])
    result = cur.fetchall()
    cur.close()
    con.close()
    return result


def get_parts_statistics():
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/Reports.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    cur.execute(sql_list[11])
    result = cur.fetchall()
    cur.close()
    con.close()
    return result


def get_monthly_sales(sold_date):
    con = psycopg2.connect(dbname=DB, user=USER, host=HOST, password=PASSWORD)
    cur = con.cursor()
    sql_file = open("sql/Reports.sql", "r")
    sql_list = sql_file.read().split(';')
    sql_file.close()
    if not sold_date:
        cur.execute(sql_list[12])
    else:
        cur.execute(sql_list[13], (sold_date,))
    result = cur.fetchall()
    cur.close()
    con.close()
    return result
