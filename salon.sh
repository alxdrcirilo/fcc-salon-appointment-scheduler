#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

SETUP_DB() {
    echo $($PSQL "TRUNCATE TABLE appointments, customers, services") >/dev/null
    echo $($PSQL "ALTER SEQUENCE appointments_appointment_id_seq RESTART WITH 1") >/dev/null
    echo $($PSQL "ALTER SEQUENCE customers_customer_id_seq RESTART WITH 1") >/dev/null
    echo $($PSQL "ALTER SEQUENCE services_service_id_seq RESTART WITH 1") >/dev/null
    echo $($PSQL "INSERT INTO services(name) VALUES('Brush'),('Cut'),('Dry')") >/dev/null
}

MAIN_MENU() {
    if [[ $1 ]]; then
        echo -e "\n$1"
    fi

    # Find selected service
    SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
    echo "$SERVICES" | while read SERVICE_ID BAR NAME; do
        echo -e "$SERVICE_ID) $NAME"
    done

    read SERVICE_ID_SELECTED

    SERVICE=$($PSQL "SELECT name FROM services WHERE service_id = '$SERVICE_ID_SELECTED'")

    # If no service found, redirect to main menu
    if [[ -z $SERVICE ]]; then
        MAIN_MENU
    else
        echo "You selected service: $SERVICE."
        SCHEDULE_MENU
    fi
}

SCHEDULE_MENU() {
    echo "Please input your phone number:"
    read CUSTOMER_PHONE

    # Get CUSTOMER_ID
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
    if [[ -z $CUSTOMER_ID ]]; then
        echo -e "New customer!\nPlease input your name:"
        read CUSTOMER_NAME
        CUSTOMER=$($PSQL "INSERT INTO 
        customers(phone, name) 
        VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")

        echo "Welcome $CUSTOMER_NAME!"

        # Set CUSTOMER_ID
        CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
    else
        CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id = '$CUSTOMER_ID'")
        echo "Welcome back $CUSTOMER_NAME!"
    fi

    echo "At what time would you like to schedule the appointment?"
    read SERVICE_TIME

    # Add appointment
    if [[ $SERVICE_TIME ]]; then
        REQUESTED_TIME=$($PSQL "INSERT INTO 
        appointments(customer_id, service_id, time) 
        VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

        if [[ "$REQUESTED_TIME" = "INSERT 0 1" ]]; then
            echo "I have put you down for a $SERVICE at $SERVICE_TIME, $CUSTOMER_NAME."
        fi
    fi
}

# Uncomment SETUP_DB if you need to cleanup the database
# SETUP_DB
MAIN_MENU
