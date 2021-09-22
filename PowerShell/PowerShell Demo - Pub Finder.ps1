#$postcode = Read-Host "Enter your postcode"
#$radius = Read-Host "Enter search radius"
#$typeofplace = Read-Host "Enter type of place"
#$keyword = Read-Host "Enter a search keyword"
#$mode = Read-Host "Enter mode of transport - Walking, Bicycling or Driving"

$mode = "driving"
$typeofplace = "pub"
$keyword = ""
$radius = "5000"
$postcode = "NE270QJ"

$fullAddress = Get-GeoCoding -Address $postcode

#Write-Host $fullAddress.Address
#Write-Host $fullAddress.Country

$country = $fullAddress.Country
#Write-Host $country

$coords = $fullAddress.Coordinates

#Write-Host "The postcode $postcode is an address in the country $country. The coordinates for this address are $coords"

Get-NearbyPlace -Coordinates $coords -Radius $radius -TypeOfPlace $typeofplace -Keyword $keyword


$listOfPlaces = Get-NearbyPlace -Coordinates $coords -Radius $radius -TypeOfPlace $typeofplace -Keyword $keyword

$listOfOpenPlaces = @()
$listOfClosedPlaces = @()
$listOfMaybePlaces = @()

foreach ($place in $listofPlaces)
{

    
    if($place.OpenNow -match "True"){
        Write-Host $place.Name " is Open"
        $listOfOpenPlaces += $place
    }
    elseif($place.OpenNow -match "False"){
        Write-Host $place.Name " is Closed"
        $listOfClosedPlaces += $place
    }
    else{
        Write-Host $place.Name " might be Open..."
        $listOfMaybePlaces += $place
    }
}


$nearestOpenPlaceName = $listOfOpenPlaces[0].Name
$nearestMaybePlaceName = $listOfMaybePlaces[0].Name

if ($nearestOpenPlaceName){
    Write-Host "The nearest $typeofplace that is open is $nearestOpenPlaceName, which matches the keyword $keyword, and is within $radius meters of the postcode $postcode. The directions to get there are below:"
    $OpenDirections = Get-Direction -From $postcode -To $listOfOpenPlaces[0] -Mode $mode
    Get-Direction -From $postcode -To $listOfOpenPlaces[0] -Mode $mode | ft -AutoSize
    $openCoOrds = $listOfOpenPlaces[0].Coordinates
    $openLat = $openCoOrds.Split(",")[0]
    $openLong = $openCoOrds.Split(",")[1]

    $headers=@{}
    $headers.Add("x-rapidapi-key", "aae71aa4e7msh8498e9ce844aecap14a409jsn3626063909d3")
    $headers.Add("x-rapidapi-host", "community-open-weather-map.p.rapidapi.com")
    $openResponse = Invoke-RestMethod -Uri "https://community-open-weather-map.p.rapidapi.com/weather?lat=$openLat&lon=$openLong&lang=en&units=metric" -Method GET -Headers $headers
    
    $opentemp = $openresponse.main.temp
    $openweather = $openresponse.weather
    $openweatherItem = $openweather.Item(0)
    $openweatherMain = $openweatherItem.Main
    $openweatherDescription = $openweatherItem.description
    $openwindSpeed = $openresponse.wind.speed

}
else{
    Write-Host "Unable to find a $typeofplace that is open within $radius meters of the postcode $postcode."
}

if ($nearestMaybePlaceName){
    Write-Host "The nearest $typeofplace that might be open is $nearestMaybePlaceName, which matches the keyword $keyword, and is within $radius meters of the postcode $postcode. The directions to get there are below:"
    Get-Direction -From $postcode -To $listOfMaybePlaces[0] -Mode $mode | ft -AutoSize
    $MaybeDirections = Get-Direction -From $postcode -To $listOfMaybePlaces[0] -Mode $mode
    $maybeCoOrds = $listOfMaybePlaces[0].Coordinates
    $maybeLat = $maybeCoOrds.Split(",")[0]
    $maybeLong = $maybeCoOrds.Split(",")[1]

    $headers=@{}
    $headers.Add("x-rapidapi-key", "aae71aa4e7msh8498e9ce844aecap14a409jsn3626063909d3")
    $headers.Add("x-rapidapi-host", "community-open-weather-map.p.rapidapi.com")
    $maybeResponse = Invoke-RestMethod -Uri "https://community-open-weather-map.p.rapidapi.com/weather?lat=$maybeLat&lon=$maybeLong&lang=en&units=metric" -Method GET -Headers $headers

    $maybetemp = $mayberesponse.main.temp
    $maybeweather = $mayberesponse.weather
    $maybeweatherItem = $maybeweather.Item(0)
    $maybeweatherMain = $maybeweatherItem.Main
    $maybeweatherDescription = $maybeweatherItem.description
    $maybewindSpeed = $mayberesponse.wind.speed

}
else{
    Write-Host "Unable to find a $typeofplace that might be open within $radius meters of the postcode $postcode."
}






if($mode -match 'walking'){

    ######## WALKING - OPEN ###########

    $totalDistance = 0
    $totalDuration = 0
    if ($nearestOpenPlaceName){
        foreach($instruction in $OpenDirections){

            $instructionDistance = $instruction.Distance
            $instructionDuration = $instruction.Duration

            if($instructionDistance -match "km$"){
                $numbers = $instructionDistance.IndexOf(" km")
                $decimal = $instructionDistance.Substring(0, $numbers)
                $int = [decimal]$decimal
                $meters = $int*1000
                $meters = [int]$meters

                $totalDistance += $meters
            }
            else{
                $numbers = $instructionDistance.IndexOf(" m")
                $int = $instructionDistance.Substring(0, $numbers)
                $meters = [int]$int
                $totalDistance += $meters
            }

            $minsIndex = $instructionDuration.IndexOf(" ")
            $minsString = $instructionDuration.Substring(0, $minsIndex)
            $minsInt = [int]$minsString
            $totalDuration += $minsInt

        }

        $arrivalTime = (Get-Date) + (New-TimeSpan -Minutes $totalDuration)



        if($totalDistance -ge 1000){
            $kilometers = $totalDistance/1000
            $calories = $kilometers*75 #arbitrary value - Indicates that for every 1km walked, this will burn 75 calories.
            Write-Host "The total distance to $nearestOpenPlaceName is $kilometers Kilometers. That will burn $calories calories whilst walking. This will take around $totalDuration minutes."
            Write-Host "The weather at $nearestOpenPlaceName is as follows: The current temperature is $opentemp degrees Celcius. The weather is: $openweatherMain ($openweatherDescription), with wind speeds of $openwindSpeed knots."
            Write-Host "Your arrival time will be "$arrivalTime.ToShortTimeString()

            }
        else {
            $calories = $kilometers*75 #arbitrary value - Indicates that for every 1km walked, this will burn 75 calories.
            Write-Host "The total distance to $nearestOpenPlaceName is $totalDistance meters. That will burn $calories calories whilst walking. This will take around $totalDuration minutes."
            Write-Host "The weather at $nearestOpenPlaceName is as follows: The current temperature is $opentemp degrees Celcius. The weather is: $openweatherMain ($openweatherDescription), with wind speeds of $openwindSpeed knots."
            Write-Host "Your arrival time will be "$arrivalTime.ToShortTimeString()
    
        }
    }
    ######## WALKING - MAYBE ###########

    $totalDistance = 0
    $totalDuration = 0

    if ($nearestMaybePlaceName){
        foreach($instruction in $MaybeDirections){
            $instructionDistance = $instruction.Distance
            $instructionDuration = $instruction.Duration

            if($instructionDistance -match "km$"){
                $numbers = $instructionDistance.IndexOf(" km")
                $decimal = $instructionDistance.Substring(0, $numbers)
                $int = [decimal]$decimal
                $meters = $int*1000
                $meters = [int]$meters

                $totalDistance += $meters
            }
            else{
                $numbers = $instructionDistance.IndexOf(" m")
                $int = $instructionDistance.Substring(0, $numbers)
                $meters = [int]$int
                $totalDistance += $meters
            }

            $minsIndex = $instructionDuration.IndexOf(" ")
            $minsString = $instructionDuration.Substring(0, $minsIndex)
            $minsInt = [int]$minsString
            $totalDuration += $minsInt
        }

        $arrivalTime = (Get-Date) + (New-TimeSpan -Minutes $totalDuration)

        if($totalDistance -ge 1000){
            $kilometers = $totalDistance/1000
            $calories = $kilometers*75 #arbitrary value - Indicates that for every 1km walked, this will burn 75 calories.
            Write-Host "The total distance to $nearestMaybePlaceName is $kilometers Kilometers. That will burn $calories calories whilst walking. This will take around $totalDuration minutes."
            Write-Host "The weather at $nearestMaybePlaceName is as follows: The current temperature is $maybetemp degrees Celcius. The weather is: $maybeweatherMain ($maybeweatherDescription), with wind speeds of $maybewindSpeed knots."
            Write-Host "Your arrival time will be "$arrivalTime.ToShortTimeString()

            }
        else {
            $kilometers = $totalDistance/1000
            $calories = $kilometers*75 #arbitrary value - Indicates that for every 1km walked, this will burn 75 calories.
            Write-Host "The total distance to $nearestMaybePlaceName is $totalDistance meters. That will burn $calories calories whilst walking. This will take around $totalDuration minutes."
            Write-Host "The weather at $nearestMaybePlaceName is as follows: The current temperature is $maybetemp degrees Celcius. The weather is: $maybeweatherMain ($maybeweatherDescription), with wind speeds of $maybewindSpeed knots."
            Write-Host "Your arrival time will be "$arrivalTime.ToShortTimeString()
    
        }
    }
}

elseif ($mode -match 'bicycling'){

    ######## BICYCLING - OPEN ###########

    $totalDistance = 0
    $totalDuration = 0
    if ($nearestOpenPlaceName){
        foreach($instruction in $OpenDirections){
            $instructionDistance = $instruction.Distance
            $instructionDuration = $instruction.Duration

            if($instructionDistance -match "km$"){
                $numbers = $instructionDistance.IndexOf(" km")
                $decimal = $instructionDistance.Substring(0, $numbers)
                $int = [decimal]$decimal
                $meters = $int*1000
                $meters = [int]$meters

                $totalDistance += $meters
            }
            else{
                $numbers = $instructionDistance.IndexOf(" m")
                $int = $instructionDistance.Substring(0, $numbers)
                $meters = [int]$int
                $totalDistance += $meters
            }

            $minsIndex = $instructionDuration.IndexOf(" ")
            $minsString = $instructionDuration.Substring(0, $minsIndex)
            $minsInt = [int]$minsString
            $totalDuration += $minsInt
        }

        $arrivalTime = (Get-Date) + (New-TimeSpan -Minutes $totalDuration)

        if($totalDistance -ge 1000){
            $kilometers = $totalDistance/1000
            $calories = $kilometers*50 #arbitrary value - Indicates that for every 1km cycled, this will burn 50 calories.
            Write-Host "The total distance to $nearestOpenPlaceName is $kilometers Kilometers. That will burn $calories calories whilst cycling. This will take around $totalDuration minutes."
            Write-Host "The weather at $nearestOpenPlaceName is as follows: The current temperature is $opentemp degrees Celcius. The weather is: $openweatherMain ($openweatherDescription), with wind speeds of $openwindSpeed knots."
            Write-Host "Your arrival time will be "$arrivalTime.ToShortTimeString()

            }
        else {
            $calories = $kilometers*50 #arbitrary value - Indicates that for every 1km cycled, this will burn 50 calories.
            Write-Host "The total distance to $nearestOpenPlaceName is $totalDistance meters. That will burn $calories calories whilst cycling. This will take around $totalDuration minutes."
            Write-Host "The weather at $nearestOpenPlaceName is as follows: The current temperature is $opentemp degrees Celcius. The weather is: $openweatherMain ($openweatherDescription), with wind speeds of $openwindSpeed knots."
            Write-Host "Your arrival time will be "$arrivalTime.ToShortTimeString()
    
        }
    }
    ######## BICYCLING - MAYBE ###########

    $totalDistance = 0
    $totalDuration = 0
    if ($nearestMaybePlaceName){
        foreach($instruction in $MaybeDirections){
            $instructionDistance = $instruction.Distance
            $instructionDuration = $instruction.Duration

            if($instructionDistance -match "km$"){
                $numbers = $instructionDistance.IndexOf(" km")
                $decimal = $instructionDistance.Substring(0, $numbers)
                $int = [decimal]$decimal
                $meters = $int*1000
                $meters = [int]$meters

                $totalDistance += $meters
            }
            else{
                $numbers = $instructionDistance.IndexOf(" m")
                $int = $instructionDistance.Substring(0, $numbers)
                $meters = [int]$int
                $totalDistance += $meters
            }

            $minsIndex = $instructionDuration.IndexOf(" ")
            $minsString = $instructionDuration.Substring(0, $minsIndex)
            $minsInt = [int]$minsString
            $totalDuration += $minsInt

        }

        $arrivalTime = (Get-Date) + (New-TimeSpan -Minutes $totalDuration)

        if($totalDistance -ge 1000){
            $kilometers = $totalDistance/1000
            $calories = $kilometers*50 #arbitrary value - Indicates that for every 1km cycled, this will burn 50 calories.
            Write-Host "The total distance to $nearestMaybePlaceName is $kilometers Kilometers. That will burn $calories calories whilst cycling. This will take around $totalDuration minutes."
            Write-Host "The weather at $nearestMaybePlaceName is as follows: The current temperature is $maybetemp degrees Celcius. The weather is: $maybeweatherMain ($maybeweatherDescription), with wind speeds of $maybewindSpeed knots."
            Write-Host "Your arrival time will be "$arrivalTime.ToShortTimeString()

        }
        else {
            $kilometers = $totalDistance/1000
            $calories = $kilometers*50 #arbitrary value - Indicates that for every 1km cycled, this will burn 50 calories.
            Write-Host "The total distance to $nearestMaybePlaceName is $totalDistance meters. That will burn $calories calories whilst cycling. This will take around $totalDuration minutes."
            Write-Host "The weather at $nearestMaybePlaceName is as follows: The current temperature is $maybetemp degrees Celcius. The weather is: $maybeweatherMain ($maybeweatherDescription), with wind speeds of $maybewindSpeed knots."
            Write-Host "Your arrival time will be "$arrivalTime.ToShortTimeString()
    
        }
    }

}

elseif ($mode -match 'driving'){


    ######## DRIVING - OPEN ###########

    $totalDistance = 0
    $totalDuration = 0
    if ($nearestOpenPlaceName){
        foreach($instruction in $OpenDirections){

            $instructionDistance = $instruction.Distance
            $instructionDuration = $instruction.Duration

            if($instructionDistance -match "km$"){
                $numbers = $instructionDistance.IndexOf(" km")
                $decimal = $instructionDistance.Substring(0, $numbers)
                $int = [decimal]$decimal
                $meters = $int*1000
                $meters = [int]$meters

                $totalDistance += $meters
            }
            else{
                $numbers = $instructionDistance.IndexOf(" m")
                $int = $instructionDistance.Substring(0, $numbers)
                $meters = [int]$int
                $totalDistance += $meters
            }

            $minsIndex = $instructionDuration.IndexOf(" ")
            $minsString = $instructionDuration.Substring(0, $minsIndex)
            $minsInt = [int]$minsString
            $totalDuration += $minsInt
        }

        $arrivalTime = (Get-Date) + (New-TimeSpan -Minutes $totalDuration)

        if($totalDistance -ge 1000){
            $kilometers = $totalDistance/1000
            $fuelusedL = $kilometers*0.06 #arbitrary value - For fuel economy.
            $fuelCost = $fuelusedL*1.21 #arbitrary value - For price per liter.
            $fuelCost = [math]::Round($fuelCost,2)

            Write-Host "The total distance to $nearestOpenPlaceName is $kilometers Kilometers. That will cost about £$fuelCost in fuel. (Around $fuelusedL litres.) This will take around $totalDuration minutes."
            Write-Host "The weather at $nearestOpenPlaceName is as follows: The current temperature is $opentemp degrees Celcius. The weather is: $openweatherMain ($openweatherDescription), with wind speeds of $openwindSpeed knots."
            Write-Host "Your arrival time will be "$arrivalTime.ToShortTimeString()
            }
        else {
            $fuelusedL = $totalDistance*0.06  #arbitrary value - For fuel economy.
            $fuelCost = $fuelusedL*1.21 #arbitrary value - For price per liter.
            $fuelCost = [math]::Round($fuelCost,2)
            Write-Host "The total distance to $nearestOpenPlaceName is $totalDistance meters. That will cost about £$fuelCost in fuel. (Around $fuelusedL litres.) This will take around $totalDuration minutes."
            Write-Host "The weather at $nearestOpenPlaceName is as follows: The current temperature is $opentemp degrees Celcius. The weather is: $openweatherMain ($openweatherDescription), with wind speeds of $openwindSpeed knots."
            Write-Host "Your arrival time will be "$arrivalTime.ToShortTimeString()
    
        }
    }

    ######## DRIVING - MAYBE ###########

    $totalDistance = 0
    $totalDuration = 0
    if ($nearestMaybePlaceName){
        foreach($instruction in $MaybeDirections){

            $instructionDistance = $instruction.Distance
            $instructionDuration = $instruction.Duration

            if($instructionDistance -match "km$"){
                $numbers = $instructionDistance.IndexOf(" km")
                $decimal = $instructionDistance.Substring(0, $numbers)
                $int = [decimal]$decimal
                $meters = $int*1000
                $meters = [int]$meters

                $totalDistance += $meters
            }
            else{
                $numbers = $instructionDistance.IndexOf(" m")
                $int = $instructionDistance.Substring(0, $numbers)
                $meters = [int]$int
                $totalDistance += $meters
            }

            $minsIndex = $instructionDuration.IndexOf(" ")
            $minsString = $instructionDuration.Substring(0, $minsIndex)
            $minsInt = [int]$minsString
            $totalDuration += $minsInt
        }

        $arrivalTime = (Get-Date) + (New-TimeSpan -Minutes $totalDuration)

        if($totalDistance -ge 1000){
            $kilometers = $totalDistance/1000
            $fuelusedL = $kilometers*0.06 #arbitrary value - For fuel economy.
            $fuelCost = $fuelusedL*1.21 #arbitrary value - For price per liter.
            $fuelCost = [math]::Round($fuelCost,2)
            Write-Host "The total distance to $nearestMaybePlaceName is $kilometers Kilometers. That will cost about £$fuelCost in fuel. (Around $fuelusedL litres.) This will take around $totalDuration minutes."
            Write-Host "The weather at $nearestMaybePlaceName is as follows: The current temperature is $maybetemp degrees Celcius. The weather is: $maybeweatherMain ($maybeweatherDescription), with wind speeds of $maybewindSpeed knots."
            Write-Host "Your arrival time will be "$arrivalTime.ToShortTimeString()

            }
        else {
            $fuelusedL = $totalDistance*0.06  #arbitrary value - For fuel economy.
            $fuelCost = $fuelusedL*1.21 #arbitrary value - For price per liter.
            $fuelCost = [math]::Round($fuelCost,2)
            Write-Host "The total distance to $nearestMaybePlaceName is $totalDistance meters. That will cost about £$fuelCost in fuel. (Around $fuelusedL litres.) This will take around $totalDuration minutes."
            Write-Host "The weather at $nearestMaybePlaceName is as follows: The current temperature is $maybetemp degrees Celcius. The weather is: $maybeweatherMain ($maybeweatherDescription), with wind speeds of $maybewindSpeed knots."
            Write-Host "Your arrival time will be "$arrivalTime.ToShortTimeString()
    
        }

    }
}


###### 