import firebase_admin
from firebase_admin import credentials, auth

# Initialize Firebase Admin SDK
cred = credentials.Certificate('serviceAccountKey.json')  # Update with your service account key path
firebase_admin.initialize_app(cred)

def get_user_uid(identifier):
    try:
        # Check if identifier is an email
        user = auth.get_user_by_email(identifier)
        return user.uid
    except auth.AuthError:
        try:
            # Assume identifier is already a uid
            auth.get_user(identifier)
            return identifier
        except auth.AuthError:
            return None

def add_admin_claim(uid_or_email):
    uid = get_user_uid(uid_or_email)
    if uid:
        try:
            # Get the user by uid
            user = auth.get_user(uid)

            # Add custom claim (admin: True)
            custom_claims = user.custom_claims or {}
            custom_claims['admin'] = True

            # Set custom user claims
            auth.set_custom_user_claims(uid, custom_claims)

            print(f"Admin claim added successfully for user {uid}")
        except firebase_admin.auth.UserNotFoundError:
            print(f"Error: User with uid {uid} not found.")
        except Exception as e:
            print(f"Error adding admin claim: {e}")
    else:
        print(f"Error: User with email or uid {uid_or_email} not found.")

def remove_admin_claim(uid_or_email):
    uid = get_user_uid(uid_or_email)
    if uid:
        try:
            # Get the user by uid
            user = auth.get_user(uid)

            # Remove admin custom claim
            custom_claims = user.custom_claims or {}
            if 'admin' in custom_claims:
                del custom_claims['admin']

            # Set custom user claims
            auth.set_custom_user_claims(uid, custom_claims)

            print(f"Admin claim removed successfully for user {uid}")
        except firebase_admin.auth.UserNotFoundError:
            print(f"Error: User with uid {uid} not found.")
        except Exception as e:
            print(f"Error removing admin claim: {e}")
    else:
        print(f"Error: User with email or uid {uid_or_email} not found.")

def main():
    while True:
        print("\nChoose an action:")
        print("1. Add admin claim for a user (by UID or Email)")
        print("2. Remove admin claim for a user (by UID or Email)")
        print("0. Exit")

        choice = input("Enter your choice: ")

        if choice == '1':
            uid_or_email = input("Enter the UID or Email of the user to add admin claim: ")
            add_admin_claim(uid_or_email)
        elif choice == '2':
            uid_or_email = input("Enter the UID or Email of the user to remove admin claim: ")
            remove_admin_claim(uid_or_email)
        elif choice == '0':
            print("Exiting program.")
            break
        else:
            print("Invalid choice. Please enter a valid option.")

if __name__ == "__main__":
    main()
