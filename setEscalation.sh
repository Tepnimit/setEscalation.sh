#!/bin/bash

#
# setEscalation.sh
#
# Description: For set Hyperic Alerts Escalation
# Created by Tepnimit Lakkanapantip - 10/07/19
# Added smart feature and modified by Tepnimit Lakkanapantip - 10/28/19
#

TODAY=`date +%m%d%y`
ENV="XXX-PR"
CFLAG=0
MFLAG=0
NFLAG=0

HOME="/app/hyperic/hqapi1-client-6.0.4/bin"
ROLE_FILE="$HOME/role.out"
ROLE_TEMP="$HOME/role_temp.out"
USER_FILE="$HOME/user.out"

SMTP_DOMAIN=xxx.com
SMTP_SENDER="HQ-$ENV@$SMTP_DOMAIN"
SMTP_SUBJECT="Hyperic Escalation - $ENV"
#SMTP_RECIPIENTS="alerts-e-host@$DOMAIN"
SMTP_RECIPIENTS="xxx$DOMAIN"
SMTP_SERVER="xxx.xxx.xxx.xxx"
SMTP_PORT="25"

cd $HOME

function selectRole() {
				clear
				echo "Listing all Roles. Please wait..."
				echo
				cat $ROLE_FILE | grep Role | grep Level | awk -F'"' '{print $2,": " $4}'
				echo "-------------------------------------"
				echo
				echo -n "Select role id: "
				read roleId
				getRole
				#./hqapi.sh role list --id=$roleId > $ROLE_FILE
				#ROLE_NAME=`cat $ROLE_FILE | grep Role | grep name | awk -F'"' '{print $4}'`
				#EXISTING_USER=`cat $ROLE_FILE | grep User | awk -F'"' '{print $2,": " $6,$8}'`
				#EXISTING_USER_ID=`cat $ROLE_FILE | grep User | awk -F'"' '{print $2},'`
				#echo
				#echo "Role name: $ROLE_NAME"
				#echo
				#echo "ID    : User"
				#echo "$EXISTING_USER"
				##echo "==========================================="
				#echo
				#echo -n "Press enter to continue"
				#read
}

function getRole() {
				$HOME/hqapi.sh role list --id=$roleId > $ROLE_TEMP
				ROLE_NAME=`cat $ROLE_TEMP | grep Role | grep name | awk -F'"' '{print $4}'`
				EXISTING_USER=`cat $ROLE_TEMP | grep User | awk -F'"' '{print $2,": " $6,$8}'`
}

function confirm() {
				echo
				echo "=================================="
				echo "Role name: $ROLE_NAME"
				echo "User name : $userId"
				echo "=================================="
				echo
				echo -n "Do you want to make the change? Please confirm (Y/N):"
				read confirmation
				CFLAG=0
				while [ $CFLAG -eq 0 ]
				do
								case $confirmation in
												[nN][oO]|[nN])
																echo "Nothing changed"
																CFLAG=1
																;;
												[yY][eE][sS]|[yY])
																cat $ROLE_TEMP | $HOME/hqapi.sh role sync
																CFLAG=1
																;;
												*)
																echo -n "The input is invalid. Please enter (Y/N):"
																CFLAG=0
																read confirmation
												;;
								esac
				done
}

function mainMenu() {
				clear
				echo
				echo "=================================="
				echo "            MAIN MENU             "
				echo "=================================="
				echo "1) Quick set Escalation"
				echo "2) Remove User from the Role"
				echo "3) Add User to the Role"
				echo "4) List User in the Role"
				#echo "5) Select the other Role"
				echo "5) List all Roles (Advance Use Only)"
				echo "q) Exit"
				echo "=================================="
				echo
				echo -n "Please select the options: "
				read action

				MFLAG=0
				while [ $MFLAG -eq 0 ]
				do
								case $action in
												[1])
																addAllUsers
																MFLAG=1
																mainMenu
																;;
												[2])
																remUser
																MFLAG=1
																mainMenu
																;;
												[3])
																addUser
																MFLAG=1
																mainMenu
																;;
												[4])
												listUser
																MFLAG=1
																mainMenu
																;;
												#[5])
												#       selectRole
												#       MFLAG=1
												#       mainMenu
												#       ;;
												[5])
												listAllRoles
																MFLAG=1
																mainMenu
																;;
												[qQ]|[qQ][uU][iI][tT])
																MFLAG=1
																echo "BYE!"
																exit 0
																;;
												*)
																echo -n "The input is invalid. (Select 1-4 or q) : "
																read action
																MFLAG=0
																;;
								esac
				done
echo

}



function menuTeam() {

				echo
				echo "=================================="
				echo "           Select Team            "
				echo "=================================="
				echo "1) Hosting"
				echo "2) Application"
				echo "3) Database"
				echo "4) Interface"
				echo "5) Security"
				echo "6) Management"
				echo "=================================="

				read team
				MFLAG=0
				while [ $MFLAG -eq 0 ]
				do
								case $team in
												[1]|Hosting)
																team="Hosting"
																MFLAG=1
																;;
												[2]|Application)
																team="Application"
																MFLAG=1
																;;
												[3]|Database)
																team="Database"
																MFLAG=1
																;;
												[4]|Interface)
																team="Interface"
																MFLAG=1
																;;
												[5]|Security)
																team="Security"
																MFLAG=1
																;;
												[6]|Management)
																team="Management"
																MFLAG=1
																;;
												*)
																echo -n "The input is invalid. (Select 1-6) : "
																read team
																MFLAG=0
																;;
								esac
				done

}


function addAllUsers() {

	clear
		menuTeam

		cat $HOME/role.out | grep Role | grep "Level Role" | grep $team > ./team.out

		# Define Array of RoleId and RoleName
		clear
		i=0
		teamRoleId=()
		teamRoleName=()
		echo
		echo "=================================="
		echo "        $team Team Roles"
		echo "=================================="
		echo "ID    : ROLE NAME"
		while read line
		do
				teamRoleId[$i]=`echo $line | awk -F'"' '{print $2}'`
				teamRoleName[$i]=`echo $line | awk -F'"' '{print $4}'`
				echo "${teamRoleId[$i]} : ${teamRoleName[$i]}"
				((i++))
		done < ./team.out

		echo
		echo -n "WARNING! All users in the Roles will be removed. Press enter to continue"
		read

		i=0
		length=`echo ${#teamRoleName[*]}`
		for (( i=0; i<$length; i++ ))
		do
				$HOME/hqapi.sh role list --id=${teamRoleId[$i]} > $ROLE_TEMP

				remAllUsersInRole

				addUsersInRole
				echo
		done

}


function selectUser() {
				#echo "Listing all Users. Please wait..."
				echo
				cat $USER_FILE | grep User\ id | grep -v -e "hqadmin" -e "guest" | awk -F'"' '{print $2,": "$10,": "$6,$8}' | sort  -t ':' -k 2
				echo "-------------------------------------"
				echo
				echo -n "Select User id: "
				read userId
				USER_ENTRY=`./hqapi.sh user list --id=$userId | grep name`
				#echo "=================================="
				#echo "User ID : $userId"
				#echo "User entry : "
				#echo "$USER_ENTRY"
				#echo "=================================="
				#echo
}

function remAllUsersInRole() {
				echo "Removing all users in ${teamRoleName[$i]}"
				#tail $ROLE_TEMP
				echo "Processing ..."
				sed -i '/User\ id/d' $ROLE_TEMP
				cat $ROLE_TEMP | $HOME/hqapi.sh role sync
				#tail $ROLE_TEMP
}

function addUsersInRole() {

				clear
				echo
				echo "============================================================"
				echo "Select user id for the escation - ${teamRoleName[$i]}"
				echo "============================================================"

				selectUser
				echo "Adding User - $userId" to $i:${teamRoleName[$i]}
				#tail $ROLE_TEMP
				#echo "Added User - $userId" to $i:${teamRoleId[$i]}
				sed -i "/\/Role\>/i $USER_ENTRY" $ROLE_TEMP

				cat $ROLE_TEMP | $HOME/hqapi.sh role sync
				#tail $ROLE_TEMP

				#Repeating
				#echo -n "Add more user in the role ${teamRoleName[$i]} (Y/N):"
				#read answer
				#MFLAG=0
				#while [ $MFLAG -eq 0 ]
				#do
				#        case $answer in
				#
				#                               [yY][eE][sS]|[yY])
				#                                               addUsersInRole
				#                                               MFLAG=1
				#                                               ;;
				#                               [nN][oO]|[nN])
				#                                               MFLAG=1
				#                                               ;;
				#                               *)
				#                                               echo -n "The input is invalid. Please enter (Y/N):"
				#                                               MFLAG=0
				#                                               read answer
				#                                               ;;
				#
				#        esac
				#done

}

function remUser() {
				clear
				selectRole
				echo
				echo "==========================================="
				echo "Role name: $ROLE_NAME"
				echo
				echo "ID    : User"
				echo "$EXISTING_USER"
				echo "==========================================="


				echo
				echo -n "Enter user id that wants to be removed : "
				read userId
				sed -i "/User\ id\=\"$userId\"/d" $ROLE_TEMP
				confirm
				echo "REMOVED USER $userId"

}


function addUser() {
				clear
				selectRole
				clear
				echo "ADD USER"
				selectUser
				sed -i "/\/Role\>/i $USER_ENTRY" $ROLE_TEMP
				confirm
				echo "Added user $userId"

}

function listUser() {
				clear
				selectRole
				echo
				echo "==========================================="
				echo "Role name: $ROLE_NAME"
				echo
				echo "ID    : User"
				echo "$EXISTING_USER"
				echo "==========================================="
				echo
				echo -n "Press enter to back to main menu"
				read

}

function listAllRoles() {
./hqapi.sh role list | grep -e "Role\ " -e  'User' | awk -F'"' '{print $2": " $4" - "$6 " " $8}' | more
echo -n "Press enter to back to main menu"
read
}

function notify() {

				#echo -n "SMTP_RECIPIENTS: "
				#read SMTP_RECIPIENTS

				echo "Sending to $SMTP_RECIPIENTS"
				echo "Sending email notification. Please wait..."
				echo
				(
				echo "Environment: $ENV";
				#       echo -n "Group name: ";
				#       ./hqapi.sh group list --id=$groupId | grep Group\ resourceId | awk -F'"' '{print $6}';
				echo "Group name: $GROUP_NAME"
				echo "Discription: Hyperic alerts will be disabled during the maintenance window"
				echo "-------------------------------------";
				./hqapi.sh maintenance get --groupId="$groupId"
				) | mailx -v -r "$SMTP_SENDER" -s "$SMTP_SUBJECT" -S smtp="$SMTP_SERVER:$SMTP_PORT" $SMTP_RECIPIENTS

}

# Load Environments and Go to Main Menu
clear
echo "Loading Environment. Please wait ..."
$HOME/hqapi.sh role list > $ROLE_FILE
$HOME/hqapi.sh user list > $USER_FILE
mainMenu
