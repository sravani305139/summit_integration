
#$work_group=$user=$org_ID=$Instance =$State=$org_ID =$servicename=$proxy =$filter=$commom_parm=$response = $res_val = $null

#Healix -Data
$Account_ID = "205"
$Apikey = "8D5A6AE6A37AC13"
$healix_Url = "http://10.181.11.53:8080/api/Agent/PushAlert/"

#Summit - Data
$user = "hoautomation@gtaa.com"
$pass = "Welcome@123"
$org_ID = "1"
$Instance = "IT"
$State = "In-Progress"


$work_group = "SERVICE DESK"#"INF-MONITORING"
$servicename = "IM_GetIncidentList"
$summit_uri = "https://itservicedeskportaldev.ppcgtaa.com/API/REST/Summit_RESTWCF.svc/RestService/CommonWS_JsonObjCall"
$proxy = "{'ReturnType': 'JSON','Password': '$pass' ,'UserName': '$user'}"
$filter = "{'OrgID': '$org_ID' ,'Instance': '$Instance' ,'Status': '$State','WorkgroupName': '$work_group'}"
$commom_parm ="{'_ProxyDetails': $proxy ,'objIncidentCommonFilter': $filter}"

try{
        function push_to_healix{
        [cmdletbinding()]
            param(
                $inc_host,$short_Desc,$id
            )
            try{
                $head = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $head.Add('apikey',$Apikey)
                $head.Add('Accept','application/json')
                $head.Add('Content-Type','application/json')

                $healix_Body = "{
                                  ""AccountId"": ""$Account_ID"",
                                  ""HostName"": ""$inc_host"",
                                  ""AlertDescription"": ""$short_Desc"",
                                  ""ITSMTicketId"": ""$id"",
                                  ""ManualParameterIdentificationRequired"": ""False""
                                }"

                $short_Desc

                $Res = Invoke-RestMethod -Method 'Post' -Uri $healix_Url -Body $healix_Body -Headers $head

                $Res.IsFailure
                $Res.Msg
                if($Res.IsFailure -like "*True*"){
                    write-host "update incident with failure note"
                }
                if($Res.IsFailure -like "*False*"){
                    write-host "update incident with success note"
                }

            }
            catch{
                $_
            
            }
        
        }
        function rest_Api_call{
        [cmdletbinding()]
            param(
                $body_data
            )

            try{
                $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $pass)))

                # Set proper headers
                $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $headers.Add('Authorization',('Basic {0}' -f $base64AuthInfo))
                $headers.Add('Accept','application/json')
                $headers.Add('Content-Type','application/json')

                $method = "post"
                
                $data = $body_data.Replace("'",'"')
                $response = Invoke-WebRequest -Headers $headers -Method $method -Uri $summit_uri -Body $data
                $res_val = $response.RawContent.Split("`n")[-1] | ConvertFrom-Json
                return $res_val.OutputObject
        
            }
            catch{
                 $_
            }
 }
        
        #fetch all the data from a work group
        $body = "{
                    ""ServiceName"": ""$servicename"",
                    ""objCommonParameters"": $commom_parm
                 }"
        
        $read_output = rest_Api_call -body_data $body

        $Inc_ID = "Incident ID" 
        $config_item = "IT_Event Details_Configuration Item"
        $ticket_dump = $read_output.MyTickets
    
        foreach($ticket in $ticket_dump){
            $id = $ticket.$Inc_ID
            $inc_host = $ticket.$config_item

            ###################
            #fetch Short description
            $inc_body = "{ 
                           ""ServiceName"":""IM_GetIncidentDetailsAndChangeHistory"",
                           ""objCommonParameters"":
                               { 
                                    '_ProxyDetails':$proxy,
                                    'TicketNo':$id
                                } 
                          } "
        
            $complete_Data = (rest_Api_call -body_data $inc_body).IncidentDetails.TicketDetails

            $short_Desc = $complete_Data.Subject
            ###################

            push_to_healix -inc_host $inc_host -short_Desc $short_Desc -id $id
        }
}
catch{
    $_
}