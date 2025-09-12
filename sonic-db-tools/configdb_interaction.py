#!/usr/bin/env python3

from swsscommon import swsscommon

def main():

    target_port = "Ethernet0"
    new_mtu = "9000"

    # Connect to CONFIG_DB
    db = swsscommon.DBConnector("CONFIG_DB", 0)

    # Open the PORT table
    port_table = swsscommon.Table(db, "PORT")
    keys = port_table.getKeys()

    print("Interfaces in CONFIG_DB:")
    for key in keys:
        print(f" - {key}")

    # Example: Read attributes of Ethernet0
    if target_port in keys:
        status, fvs = port_table.get(target_port)
        if status:
            print("\nAttributes of Ethernet0:")
            for field, value in fvs:
                print(f"   {field}: {value}")

    # Update MTU of Ethernet0
    print(f"\nUpdating {target_port} MTU to {new_mtu} ...")
    port_table.set(target_port, [("mtu", new_mtu)])

    # Read back to verify
    status, fvs = port_table.get(target_port)
    if status:
        print(f"\nUpdated attributes of {target_port}:")
        for field, value in fvs:
            print(f"   {field}: {value}")

if __name__ == "__main__":
    main()
