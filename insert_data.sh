#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
  
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

   #This echo with $() outputs the result to echo
    echo $($PSQL "TRUNCATE teams,games")
    counter=0
    fileCSV=games.csv
    
    
    ## INSERT in teams Table
    
    # Create an array to store the unique team values
    teams=()
    
    # Read the fileCSV and extract the "winner" column
    while IFS=',' read -r YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS; do
        
        # Skip the header line
        if [[ $YEAR != "year" ]]; then
            
            # Check if the winner is not already in the teams array. [*] expands the elements of the teams array into a single string, separated by spaces. then " $WINNER " checks with surrounded spaces
            if ! [[ " ${teams[*]} " =~ " $WINNER " ]]; then
                teams+=("$WINNER")
            fi
            if ! [[ " ${teams[*]} " =~ " $OPPONENT " ]]; then
                teams+=("$OPPONENT")
            fi
        fi
    done < $fileCSV
    
    # Adding each team into teams table
    for team in "${teams[@]}"; do
        
        #get team_id
        TEAM_ID=$($PSQL "select team_id from teams where name='$team'")
        
        #if TEAM_ID not found
        if [[ -z $TEAM_ID ]]
        then
            TEAM_ID_RESULT=$($PSQL "insert into teams(name) values('$team')")
            if [[ $TEAM_ID_RESULT == "INSERT 0 1" ]]
            then
                echo Inserted into teams, $team
            fi
        fi
    done
    
    ## INSERT in games Table
    
    #To avoid loss of var in pipe this structure works: (https://mywiki.wooledge.org/ProcessSubstitution)
    while IFS="," read -r YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS; do
        if [[ $YEAR != "year" ]]
        then
            #get winner_id
            WINNER_ID=$($PSQL "select team_id from teams where name='$WINNER'")
            
            #get opponent_id
            OPPONENT_ID=$($PSQL "select team_id from teams where name='$OPPONENT'")
            
            #get game_id
            GAME_ID=$($PSQL "select * from games full join teams on games.winner_id=teams.team_id where round='$ROUND' and winner_id='$WINNER_ID' and opponent_id='$OPPONENT_ID'")
            
            # if not found 
            if [[ -z $GAME_ID ]]
            then
                GAME_RESULT=$($PSQL "Insert into games(year,round,winner_id,opponent_id,winner_goals,opponent_goals) values($YEAR,'$ROUND',$WINNER_ID,$OPPONENT_ID,$WINNER_GOALS,$OPPONENT_GOALS)")
                if [[ $GAME_RESULT == "INSERT 0 1" ]]
                then
                    echo Inserted into teams, $YEAR $ROUND $WINNER $OPPONENT $WINNER_GOALS $OPPONENT_GOALS
                fi
                
                #For testing:
                counter=$(( counter+1 ))
            fi
        fi
        
    done < <(cat $fileCSV) #for Process Substitution
    echo "$counter"
