from flask import Flask, session, render_template, request, url_for, redirect, flash
from datetime import date
from database import *

app = Flask(__name__)
app.secret_key = 'fdsafasd'
app.debug = True


@app.route('/login', methods=['POST'])
def login():
    if request.method == 'POST':
        username = request.form['username'].lower()
        password = request.form['password']
        if username in list_one_column('username', 'users') and verify(username, password):
            session.clear()
            if check_usertype(username, 'owner'):
                session['usertype'] = 'owner'
            elif check_usertype(username, 'manager'):
                session['usertype'] = 'manager'
            elif check_usertype(username, 'salesperson'):
                session['usertype'] = 'salesperson'
            elif check_usertype(username, 'servicewriter'):
                session['usertype'] = 'servicewriter'
            elif check_usertype(username, 'inventoryclerk'):
                session['usertype'] = 'inventoryclerk'
            session['username'] = username
            # message = "You were successfully logged in"
            return redirect(url_for("search"))
        else:
            message = "Please enter correct username and/or password"
        return render_template('search.html',
                               message=message)


@app.route('/logout/')
def logout():
    session.clear()
    return redirect(url_for("search"))
    # return render_template('search.html', message="You were successfully logged out")


@app.route('/add_vehicle', methods=['GET', 'POST'])
def add_vehicle():
    if 'usertype' in session and session['usertype'] in ['owner', 'inventoryclerk']:
        m_list = populate_dropdowns('manufacturer_name', 'manufacturer')
        colors_list = ['Aluminum', 'Beige', 'Black', 'Blue', 'Brown', 'Bronze', 'Claret',
                       'Copper', 'Cream', 'Gold', 'Gray', 'Green', 'Maroon', 'Metallic',
                       'Navy', 'Orange', 'Pink', 'Purple', 'Red', 'Rose', 'Rust', 'Silver',
                       'Tan', 'Turquoise', 'White', 'Yellow']
        if request.method == 'POST':
            vtype = request.form['vtype']
            manufacturer = request.form.get('manufacturer')
            vin = request.form['vin'].upper()
            model_name = request.form['model_name'].upper()
            model_year = request.form['model_year']
            invoice_price = request.form.get('invoice_price')
            colors = request.form.getlist('colors')
            desc = request.form['description']
            date_added = date.today()
            username = session['username']
            doors_count = request.form.get('doors_count')
            drivetrain_type = request.form.get('drivetrain_type').upper()
            cupholders_count = request.form.get('cupholders_count')
            roof_type = request.form.get('roof_type')
            back_seat_count = request.form.get('back_seat_count')
            has_back_door = request.form.get('has_back_door')
            cover_type = request.form.get('cover_type')
            rear_axles_count = request.form.get('rear_axles_count')
            cargo_capacity = request.form.get('cargo_capacity')
            result = add_vehicle_db(manufacturer, vin, model_year, model_name, invoice_price,
                                    desc, date_added, username, colors, vtype, has_back_door,
                                    doors_count, drivetrain_type, cupholders_count, roof_type,
                                    back_seat_count, cover_type, rear_axles_count, cargo_capacity)
            if result[0]:
                return redirect(url_for('vehicle_details',
                                        vin=vin))
            else:
                message = result[1]
                return render_template('add_vehicle.html',
                                       m_list=m_list,
                                       colors=colors_list,
                                       curr_year=date.today().year, message=message)
        return render_template('add_vehicle.html',
                               m_list=m_list,
                               colors=colors_list,
                               curr_year=date.today().year)
    return render_template('page_not_found.html')


@app.route('/', methods=['GET', 'POST'])
def search():
    total_vehicles = get_total_vehicle()
    manufacturers_list = populate_dropdowns('manufacturer_name', 'vehicle')
    model_year_list = populate_dropdowns('model_year', 'vehicle')
    colors_list = populate_dropdowns('color', 'vehiclecolors')
    is_owner_manager = False
    is_logged_in = False
    results = None
    message = ''
    if 'usertype' in session and session['usertype'] in ['owner', 'manager']:
        is_owner_manager = True
    if 'usertype' in session:
        is_logged_in = True
    if request.method == 'POST':
        vehicle_type = request.form.get('VehicleType')
        manufacturer = request.form.get('ManufacturerName')
        color = request.form.get('Color')
        model_year = request.form.get('ModelYear')
        min_price = request.form.get('MinPrice')
        max_price = request.form.get('MaxPrice')
        keyword = request.form.get('Keyword').strip()
        vin = request.form.get('Vin')
        if vin:
            vin = vin.upper()
        if vehicle_type or manufacturer or color or model_year or min_price or \
                max_price or keyword or vin:
            keyword = "%" + keyword + "%"
            if color:
                color = "%" + color + "%"
            else:
                color = "%%"
            if is_owner_manager:
                results = get_search_results(vin, vehicle_type, manufacturer, color,
                                             model_year, min_price, max_price, keyword, 1)
            else:
                results = get_search_results(vin, vehicle_type, manufacturer, color,
                                             model_year, min_price, max_price, keyword, 0)
            if results:
                return render_template('search.html',
                                       total_vehicles=total_vehicles,
                                       manufacturers_list=manufacturers_list,
                                       results=results,
                                       model_year_list=model_year_list,
                                       colors_list=colors_list,
                                       is_owner_manager=is_owner_manager,
                                       is_logged_in=is_logged_in)
            else:
                message = "Sorry, it looks like we don’t have that in stock!"
        else:
            message = "Some input for search is required"
    return render_template('search.html',
                           message=message,
                           total_vehicles=total_vehicles,
                           manufacturers_list=manufacturers_list,
                           results=results,
                           model_year_list=model_year_list,
                           colors_list=colors_list,
                           is_owner_manager=is_owner_manager,
                           is_logged_in=is_logged_in)


@app.route('/vehicle_details/<vin>')
def vehicle_details(vin):
    status = get_status(vin)
    session.pop('currCustomerId', None)
    details = get_vehicle_details(vin, 1)
    repairs_info = get_vehicle_details(vin, 0)
    is_owner_manager = False
    is_logged_in = False
    is_sales_person = False
    is_inventory_clerk = False
    if 'usertype' in session and session['usertype'] in ['owner', 'manager']:
        is_owner_manager = True
    if 'usertype' in session:
        is_logged_in = True
    if 'usertype' in session and session['usertype'] in ['owner', 'salesperson']:
        is_sales_person = True
    if 'usertype' in session and session['usertype'] in ['inventoryclerk']:
        is_inventory_clerk = True
    return render_template('vehicle_details.html',
                           details=details,
                           repairs_info=repairs_info,
                           is_owner_manager=is_owner_manager,
                           is_logged_in=is_logged_in,
                           is_sales_person=is_sales_person,
                           is_inventory_clerk=is_inventory_clerk,
                           vin=vin,
                           status=status)


@app.route('/lookup_customer', methods=['GET', 'POST'])
def lookup_customer():
    if 'usertype' in session and session['usertype'] in ['owner', 'servicewriter', 'salesperson']:
        if request.method == 'POST':
            message = ""
            if request.form.get('lookup_action') == 'Search':
                customer_type = request.form['CustomerType']
                id_no = None
                if customer_type == 'Individual':
                    id_no = request.form['DlNo']
                elif customer_type == 'Business':
                    id_no = request.form['TaxId']
                result = get_customer_db(customer_type, id_no, None)
                if not result:
                    message = "No customer found"
                else:
                    session['currCustomerId'] = result[0][9]
                return render_template('lookup_customer.html',
                                       data=result,
                                       message=message)
            if request.form.get('choose_customer') == 'Choose Customer':
                return redirect(session['prev_url'])
        return render_template('lookup_customer.html')
    return render_template('page_not_found.html')


@app.route('/add_customer', methods=["GET", "POST"])
def add_customer():
    if 'usertype' in session and session['usertype'] in ['owner', 'servicewriter', 'salesperson']:
        if request.method == 'POST':
            if request.form.get('add') == 'Add Customer':
                customer_type = request.form['CustomerType']
                street = request.form['Street']
                city = request.form['City']
                state = request.form['State']
                postal_code = request.form['PostalCode']
                email = request.form['Email']
                phone = request.form['Phone']
                if customer_type == 'Individual':
                    dl_no = request.form['DlNo']
                    first_name = request.form['FirstName']
                    last_name = request.form['LastName']
                    add_result = add_customer_db(
                        [email, phone, street, city, state, postal_code, dl_no, first_name, last_name], None)
                    if not add_result:
                        message = "Customer already exists"
                        return render_template('add_customer.html',
                                               message=message)
                    else:
                        session['currCustomerId'] = add_result[0]
                elif customer_type == 'Business':
                    tax_id_no = request.form['TaxId']
                    business_name = request.form['BusinessName']
                    contact_name = request.form['PrimaryContactName']
                    contact_title = request.form['PrimaryContactTitle']
                    add_result = add_customer_db(None,
                                                 [email, phone, street, city,
                                                  state, postal_code,
                                                  tax_id_no, business_name,
                                                  contact_name, contact_title])
                    if not add_result:
                        message = "Customer already exists."
                        return render_template('add_customer.html',
                                               message=message)
                    else:
                        session['currCustomerId'] = add_result[0]
                return redirect(session['prev_url'])
        return render_template('add_customer.html')
    return render_template('page_not_found.html')


@app.route('/sell_vehicle/<vin>', methods=['POST', 'GET'])
def sell_vehicle(vin):
    if 'usertype' in session and session['usertype'] in ['owner', 'salesperson']:
        session['prev_url'] = url_for('sell_vehicle',
                                      vin=vin)
        min_sale_price = 0
        result = None
        invoice_price = get_price(vin)
        message = None
        if 'currCustomerId' in session:
            result = get_customer_db(None, None, session['currCustomerId'])
        if session['usertype'] != 'owner':
            min_sale_price = (float(invoice_price) * 0.95) + 0.01
        if request.method == 'POST':
            if 'currCustomerId' in session:
                sold_price = float(request.form['price'])
                if sold_price >= min_sale_price:
                    if sell_vehicle_db(vin, session['currCustomerId'], session['username'], sold_price, date.today()):
                        flash("Congratulations, vehicle has been successfully sold!")
                        session.pop('currCustomerId', None)
                        return redirect(url_for('vehicle_details', vin=vin))
                    else:
                        message = "Vehicle can be sold only once. Please select another vehicle from Search tab"
                        session.pop('currCustomerId', None)
                        return render_template('sell_vehicle.html',
                                               vin=vin,
                                               min_sale_price=min_sale_price,
                                               invoice_price=invoice_price,
                                               data=result,
                                               message=message)
            else:
                message = "Choose customer first"
        return render_template('sell_vehicle.html',
                               vin=vin,
                               min_sale_price=min_sale_price,
                               invoice_price=invoice_price,
                               data=result,
                               message=message)
    return render_template('page_not_found.html')


@app.route('/repairs/', defaults={'vin': ''}, methods=['POST', 'GET'])
@app.route('/repairs/<vin>')
def repairs(vin=''):
    if 'usertype' in session and session['usertype'] in ['owner', 'servicewriter']:
        message = None
        vehicle_found = False
        details = None
        result = None
        open_repair = None
        min_labor_charges = 0
        labor_charges = 0
        description = None
        if vin:
            session['prev_url'] = '/repairs/' + vin
            vehicle_found = True
            details = get_repairs_info(vin, "vehicle_info")
            open_repair = get_repairs_info(vin, "open_repair")
        if 'currCustomerId' in session:
            result = get_customer_db(None, None, session['currCustomerId'])
        if open_repair:
            labor_charges = get_prev_data(vin)[0]
            description = get_prev_data(vin)[1]
            if session['usertype'] != 'owner':
                min_labor_charges = labor_charges
        if request.method == 'POST':
            if 'vin' in session:
                vin = session['vin']
            if 'Lookup vehicle' in request.form:
                vin = request.form['vin'].upper()
                if vin in list_one_column('vin', 'vehicle'):
                    if vin in list_one_column('vin', 'sale'):
                        session['vin'] = vin
                        session.pop('currCustomerId', None)
                        return redirect(url_for('repairs',
                                                vin=vin))
                    else:
                        message = "The vehicle has not been sold yet"
                else:
                    message = "The vehicle vin does not exist"
            if 'Create repair' in request.form:
                if 'currCustomerId' in session:
                    start_date = date.today()
                    if start_date not in get_start_date(vin):
                        odometer = request.form.get('odometer')
                        username = session['username']
                        customer = session['currCustomerId']
                        if add_repair_db(vin, odometer, username, customer, start_date):
                            return redirect(url_for('repairs',
                                                    vin=vin))
                    else:
                        message = "You can create only 1 repair per day"
                else:
                    message = "Choose customer first"
            if 'Update repair' in request.form:
                labor_charges = request.form['labor_charges']
                description = request.form['description']
                start_date = get_start_date(vin)
                if update_repair_db(vin, labor_charges, description, start_date):
                    return redirect(url_for('repairs', vin=vin))
                return redirect(url_for('search'))
            if 'Complete repair' in request.form:
                labor_charges = request.form['labor_charges']
                description = request.form['description']
                start_date = get_start_date(vin)
                end_date = date.today()
                if update_repair_db(vin, labor_charges, description, start_date):
                    if complete_repair_db(vin, start_date, end_date):
                        session.pop('currCustomerId', None)
                        return redirect(url_for('repairs', vin=vin))
                return redirect(url_for('search'))
        return render_template('repairs.html',
                               vin=vin,
                               message=message,
                               vehicle_found=vehicle_found,
                               details=details,
                               open_repair=open_repair,
                               data=result,
                               description=description,
                               labor_charges=labor_charges,
                               min_labor_charges=min_labor_charges)
    return render_template('page_not_found.html')


@app.route('/add_part/<vin>', methods=['GET', 'POST'])
def add_part(vin):
    if 'usertype' in session and session['usertype'] in ['owner', 'servicewriter']:
        message = ''
        if request.method == 'POST':
            part_no = request.form['part_no']
            vendor_name = request.form['vendor_name']
            quantity = request.form['quantity']
            price = request.form['price']
            start_date = get_start_date(vin)
            if add_part_db(part_no, start_date, vin, vendor_name, price, quantity):
                return redirect(url_for('repairs', vin=vin))
            else:
                message = "You have already entered this part for this repair. Please enter different Part number!"
        return render_template('add_part.html', vin=vin, message=message)
    return render_template('page_not_found.html')


# =============================== REPORTS =====================================


@app.route('/reports')
def reports():
    if 'usertype' in session and session['usertype'] in ['owner', 'manager']:
        return render_template('reports.html')
    return render_template('page_not_found.html')


@app.route('/sales_color')
def sales_by_color():
    if 'usertype' in session and session['usertype'] in ['owner', 'manager']:
        data = get_sales_by("color")
        return render_template('reports/sales_by.html',
                               report_type="Color",
                               data=data)
    return render_template('page_not_found.html')


@app.route('/sales_type')
def sales_by_type():
    if 'usertype' in session and session['usertype'] in ['owner', 'manager']:
        data = get_sales_by("type")
        return render_template('reports/sales_by.html',
                               report_type="Type",
                               data=data)
    return render_template('page_not_found.html')


@app.route('/sales_manufacturer')
def sales_by_manufacturer():
    if 'usertype' in session and session['usertype'] in ['owner', 'manager']:
        data = get_sales_by("manufacturer")
        return render_template('reports/sales_by.html',
                               report_type="Manufacturer",
                               data=data)
    return render_template('page_not_found.html')


@app.route('/gross_customer_income/', defaults={'customer_id': ''})
@app.route('/gross_customer_income/<customer_id>')
def gross_customer_income(customer_id=''):
    if 'usertype' in session and session['usertype'] in ['owner', 'manager']:
        if customer_id == '':
            customers = get_gross_customer_income(None)[0]
            return render_template('reports/gross_customer_income.html',
                                   customers=customers)
        else:
            sales_income = get_gross_customer_income(customer_id)[1]
            repairs_income = get_gross_customer_income(customer_id)[2]
            return render_template('reports/gross_customer_income.html',
                                   customerId=customer_id,
                                   sales=sales_income,
                                   repairs=repairs_income)
    return render_template('page_not_found.html')


@app.route('/repairs_by/', defaults={'manufacturer': '', 'vehicle_type': ''})
@app.route('/repairs_by/<manufacturer>/')
@app.route('/repairs_by/<manufacturer>/<vehicle_type>')
def repairs_by(manufacturer='', vehicle_type=''):
    if 'usertype' in session and session['usertype'] in ['owner', 'manager']:
        if manufacturer == '':
            manufacturers = get_repairs_by(None, None)
            return render_template('reports/repairs_by.html',
                                   manufacturers=manufacturers)
        elif vehicle_type == '':
            vehicle_types = get_repairs_by(manufacturer, None)
            return render_template('reports/repairs_by.html',
                                   manufacturer=manufacturer,
                                   vehicle_types=vehicle_types)
        else:
            models = get_repairs_by(manufacturer, vehicle_type)
            return render_template('reports/repairs_by.html',
                                   manufacturer=manufacturer,
                                   vehicle_type=vehicle_type,
                                   models=models)
    return render_template('page_not_found.html')


@app.route('/below_cost_sales')
def below_cost_sales():
    data = get_below_cost_sales()
    return render_template('reports/below_cost_sales.html',
                           data=data)


@app.route('/avg_time_in_inventory')
def avg_time_in_inventory():
    data = get_avg_time_in_inventory()
    return render_template('reports/avg_time_in_inventory.html',
                           data=data)


@app.route('/parts_statistics')
def parts_statistics():
    data = get_parts_statistics()
    return render_template('reports/parts_statistics.html',
                           data=data)


@app.route('/monthly_sales/', defaults={'sold_date': ''})
@app.route('/monthly_sales/<sold_date>')
def monthly_sales(sold_date=''):
    if sold_date == '':
        data = get_monthly_sales(None)
        return render_template('reports/monthly_sales.html',
                               data=data)
    else:
        data = get_monthly_sales(sold_date)
        return render_template('reports/monthly_sales.html',
                               data=data,
                               sold_date=sold_date)


if __name__ == '__main__':
    app.run()
