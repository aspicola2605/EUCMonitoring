Function Show-EUCResult {
    <#
.SYNOPSIS
    Console based output
    
.DESCRIPTION
    Console Based output
.PARAMETER Results
    The path to the JSON config file.  
.NOTES
    Current Version:        1.0
    Creation Date:          07/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough            1.0          17/05/2018          Function Creation

.EXAMPLE
    None Required
#>
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Results
    ) 

    # We want all results to represent the same moment in time, even if that's not true for 
    # collation reasons. This is why this step happens at the end. 
    $timeStamp = (get-date)
         
    Write-Verbose "$(ConvertTo-JSON -inputObject $Results -Depth 4)"
    Write-Verbose "Showing results:"
    foreach ($SeriesName in $Results) { 

        $Series = $SeriesName.Series
        Write-Verbose "Series: $Series"

        foreach ($Result in $SeriesName.Results) {

            # XXX CHANGEME XXX 
            #$Series = "TEMPLATE"
            #This assumes influx doesn't care about the order as long as they're grouped
            # Ports Up
            $ParamString = ""
            foreach ( $Port in $Result.PortsUp ) {
                if ( $ParamString -eq "" ) { $ParamString = "Port$Port=1" } 
                else { $ParamString += ",Port$Port=1" }
            }
            foreach ( $Port in $Result.PortsDown ) {
                if ( $ParamString -eq "" ) { $ParamString = "Port$Port=0" } 
                else { $ParamString += ",Port$Port=0" }
            }

 
            # This assumes influx doesn't care about the order as long as they're grouped.
            # 1 Means Up, 0 means Down.  
            # Services Up

            foreach ( $Service in $Result.ServicesUp ) {
                if ( $ParamString -eq "" ) { $ParamString = "$Service=1" } 
                else { $ParamString += ",$Service=1" }
            }
            foreach ( $Service in $Result.ServicesDown ) {
                if ( $ParamString -eq "" ) { $ParamString = "$Service=0" } 
                else { $ParamString += ",$Service=0" }
            }

            #This assumes influx doesn't care about the order as long as they're grouped
            # Checks Up

            foreach ( $Check in $Result.ChecksUp ) {
                if ( $ParamString -eq "" ) { $ParamString = "$Check=1" } 
                else { $ParamString += ",$Check=1" }
            }
            foreach ( $Service in $Result.ChecksDown ) {
                if ( $ParamString -eq "" ) { $ParamString = "$Check=0" } 
                else { $ParamString += ",$Check=0" }
            }

            # That's all the binary checks.  
            if ( "" -ne $ParamString ) {
                $ParamString = $ParamString -replace " ", "\ "
                $PostParams = "$Series,Server=$($Result.ComputerName) $ParamString $timeStamp"
                Write-Verbose $PostParams
                Write-Output $PostParams
            }

            # Stoplight checks
            if ( "UP" -eq $Result.State ) { $ParamString = "State=2" }
            elseif ( "DEGRADED" -eq $Result.State ) { $ParamString = "State=1" }
            else { $ParamString = "State=0" }

            $PostParams = "$Series-StopLights,Server=$($Result.ComputerName) $ParamString $timeStamp"
            Write-Output $PostParams

            # Unique Numerical Data will follow
            # ValueName=NumericalValue
            foreach ( $CheckData in $Result.CheckData ) {
                $ParamString = ""
                $CheckDataName = $CheckData.PSObject.Properties.Name
                $CheckDataValue = $CheckData.PSObject.Properties.Value
                <#
                Should look like
                Results.Series.ComputerName.CheckData.XdDesktop
                Registered=3
                Unregistered=2
                ...
                #>

                foreach ( $Sub in $CheckDataValue ) {
                    $SubName = $Sub.PSObject.Properties.Value
                    $SubValue = $Sub.PSObject.Properties.Value
                    if ( $ParamString -eq "" ) { $ParamString = "$SubName=$SubValue" } 
                    else { $ParamString += ",$SubName=$SubValue" }
                }

                if ( "" -ne $ParamString ) {
                    $ParamString = $ServiceString -replace " ", "\ "
                    $PostParams = "$Series-$CheckDataName,Server=$($Result.ComputerName) $ParamString $timeStamp"
                    Write-Verbose $PostParams
                    Write-Output $PostParams
                }
            
            }
        }
    }
}
