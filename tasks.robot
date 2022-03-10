*** Settings ***
Test Teardown     Close Browser
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.FileSystem
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           String
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

*** Variables ***
${URL}    https://robotsparebinindustries.com/
${PDF_OUTPUT_DIRECTORY}    ${OUTPUTDIR}${/}receipts

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders}    Get orders
    Log    ${orders}
    Open the robot order website
    FOR    ${row}    IN    @{orders}
        Log    ${row}      
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${row}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
    Open Browser    ${URL}    chrome
    Maximize Browser Window
    Wait And Click  //*[contains(text(), 'Order your robot!')]

Get Orders
    ${CSVURL}    Collect CSV URL from user
    RPA.HTTP.Download    ${CSVURL}    overwrite=True
    #RPA.HTTP.Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${table}    Read table from CSV    orders.csv    dialect=excel
    Close Browser
    [return]    ${table}

Close the annoying modal
    Wait And Click    //*[@class="btn btn-dark"]

Fill the form
    [Arguments]    ${row}
    Wait And Click    //*[@id="head"]
    Wait And Click    //*[@id='head']/option[@value='${row}[Head]']
    Wait And Click    //*[@id="id-body-${row}[Body]"]
    Wait And Input Text    //*[@placeholder="Enter the part number for the legs"]    ${row}[Legs]  
    Wait And Input Text    //*[@id="address"]    ${row}[Address]  
    
Preview the robot
    Wait And Click    //*[@id="preview"]

Submit the order
    Wait And Click    //*[@id="order"]
    Wait Until Keyword Succeeds    3x    0.5 sec    Check That Order Went Through

Check That Order Went Through
    ${status}    Run Keyword And Return Status    Wait Until Element Is Visible  //*[@id="receipt"]    2s
    Log    ${status}
    Sleep  2
    Run Keyword If	'${status}' == 'False'    Wait Until Keyword Succeeds    3x    1sec    Wait And Click    //*[@id="order"]

Store the receipt as a PDF file
    [Arguments]    ${receipt}
    Log    ${receipt}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${PDF_OUTPUT_DIRECTORY}${/}receipt_${receipt}.pdf

Take a screenshot of the robot
    [Arguments]    ${receipt}
    ${screenshot}    Capture Element Screenshot    id:robot-preview-image    ${OUTPUTDIR}/image_${receipt}.png
    [return]    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${row}   
    ${files}    Create List    ${OUTPUTDIR}${/}image_${row}.png
    Open PDF    ${PDF_OUTPUT_DIRECTORY}${/}receipt_${row}.pdf
    Add Files To Pdf    ${files}    ${PDF_OUTPUT_DIRECTORY}${/}receipt_${row}.pdf    append=True
    Close All Pdfs

Go to order another robot
    Wait And Click    //*[@id="order-another"]

Create a ZIP file of the receipts
    ${zip_file_name}    Set Variable    ${PDF_OUTPUT_DIRECTORY}/PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}

Collect CSV URL from user
    Add heading    Please give the URL for CSV file
    Add text input    url
    ...    label=URL
    ...    placeholder=Enter URL here
    ...    rows=5
    ${result}=    Run dialog
    [return]    ${result}

Wait And Click
    [Arguments]    ${path}
    Wait Until Element Is Visible    ${path}
    Sleep  0.25
    Click Element    ${path}

Wait And Input Text
    [Arguments]    ${path}    ${text}
    Wait Until Element Is Visible    ${path}
    Sleep  0.25
    Input Text    ${path}    ${text}


