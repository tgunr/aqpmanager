<?php 
// Set the request paramaeter 
$email = "davec@polymicrosystems.com"; 
$header = ""; 
$emailtext = ""; 
$req = 'cmd=_notify-validate'; 

// Run through the posted array 
foreach ($_POST as $key => $value) 
{ 
    // If magic quotes is enabled strip slashes 
    if (get_magic_quotes_gpc()) 
    { 
        $_POST[$key] = stripslashes($value); 
        $value = stripslashes($value); 
    } 
    $value = urlencode($value); 
    // Add the value to the request parameter 
    $req .= "&$key=$value"; 
} 

$url = "http://www.sandbox.paypal.com/cgi-bin/webscr"; 
$ch = curl_init();    // Starts the curl handler 
curl_setopt($ch, CURLOPT_URL,$url); // Sets the paypal address for curl 
curl_setopt($ch, CURLOPT_FAILONERROR, 1); 
curl_setopt($ch, CURLOPT_RETURNTRANSFER,1); // Returns result to a variable instead of echoing 
curl_setopt($ch, CURLOPT_TIMEOUT, 3); // Sets a time limit for curl in seconds (do not set too low) 
curl_setopt($ch, CURLOPT_POST, 1); // Set curl to send data using post 
curl_setopt($ch, CURLOPT_POSTFIELDS, $req); // Add the request parameters to the post 
$result = curl_exec($ch); // run the curl process (and return the result to $result 
curl_close($ch); 

if (strcmp ($result, "VERIFIED") == 0) // It may seem strange but this function returns 0 if the result matches the string So you MUST check it is 0 and not just do strcmp ($result, "VERIFIED") (the if will fail as it will equate the result as false) 
{ 
    // Do some checks to ensure that the payment has been sent to the correct person 
    // Check and ensure currency and amount are correct 
    // Check that the transaction has not been processed before 
    // Ensure the payment is complete 
	$req = "cmd=_notify-validate\n";
	
	foreach ($_POST as $key => $value) {
		$value = urlencode(stripslashes($value));
		$req .= "&$key=$value\n";
	}
	mail($email, "Live-VERIFIED IPN", $emailtext . "\n\n" . $req); 
} 
else  
{ 
	mail($email, "Live-VERIFIED IPN FAILED", $emailtext); 
} 
?>