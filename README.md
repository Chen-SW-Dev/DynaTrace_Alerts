# DynaTrace_Alerts
Automatic SolarWinds Alerts Creation based on DynaTrace Problems

This is a SAM template which contains a powershell script component that does the following :

1) Pulling "Open" Problems (last 1hour) in DynaTrace via RESTAPI and saving the response as json in a directory in C:\ drive.
2) Then for each Problem ID detected in the json file the script will create an alert based on a XML template (provided) and then it will invoke swis to import that alert to Orion.
3) The aler templates doesn't contain any trigger/rest action, you may import the inital aler templat and add actions per your needs.
4) The script returns number of problems and the raw rest response to solarwinds for Alert reset purposes. 

* The alert will clear automatlically once the original Problem ID isn't in open status anymore (not returned in the rest response).
* The script will not create an alert if there is existing alert in Orion with the same Problem ID.
