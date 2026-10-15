#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -q -c"
secret_number=$(( RANDOM % 1000 + 1 ))

echo "Enter your username:"
read -r username

username_sql=${username//\'/\'\'}
user_info=$($PSQL "SELECT user_id || '|' || (SELECT COUNT(*) FROM games WHERE user_id = users.user_id) || '|' || COALESCE((SELECT MIN(number_of_guesses) FROM games WHERE user_id = users.user_id), 0) || '|' || username FROM users WHERE username = '$username_sql';")

if [[ -z $user_info ]]; then
	user_id=$($PSQL "INSERT INTO users(username) VALUES ('$username_sql') RETURNING user_id;")
	echo "Welcome, $username! It looks like this is your first time here."
else
	IFS='|' read -r user_id games_played best_game stored_username <<< "$user_info"
	echo "Welcome back, $stored_username! You have played $games_played games, and your best game took $best_game guesses."
fi

echo "Guess the secret number between 1 and 1000:"
read -r guess
number_of_guesses=1

while true; do
	if [[ ! $guess =~ ^[+-]?[0-9]+$ ]]; then
		echo "That is not an integer, guess again:"
	else
		guess_sign=positive
		guess_digits=$guess
		if [[ $guess_digits == -* ]]; then
			guess_sign=negative
			guess_digits=${guess_digits#-}
		elif [[ $guess_digits == +* ]]; then
			guess_digits=${guess_digits#+}
		fi
		while [[ ${#guess_digits} -gt 1 && $guess_digits == 0* ]]; do
			guess_digits=${guess_digits#0}
		done

		if [[ $guess_sign == negative && $guess_digits != 0 ]]; then
			echo "It's higher than that, guess again:"
		elif [[ ${#guess_digits} -gt ${#secret_number} ]] || { [[ ${#guess_digits} -eq ${#secret_number} ]] && [[ $guess_digits > $secret_number ]]; }; then
			echo "It's lower than that, guess again:"
		elif [[ $guess_digits == "$secret_number" ]]; then
			break
		else
			echo "It's higher than that, guess again:"
		fi
	fi
	read -r guess
	((number_of_guesses++))
done

$PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES ($user_id, $number_of_guesses);"
echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"