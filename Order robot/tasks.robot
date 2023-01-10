*** Settings ***
Documentation       Template robot main suite.

Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.Dialogs
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF    
Library    RPA.Archive
Library    OperatingSystem
Library    Collections
Library    RPA.Robocorp.Vault
Library    Dialogs
    
Suite Teardown    Close All Browsers

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Create temp directories
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    2min    500ms   Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
   END
    Create a ZIP file of the receipts   zip_directory
    Close Browser and cleanup
    


*** Variables ***
${URl}       https://robotsparebinindustries.com/#/robot-order

${ordercolumn}     "Order number"
${Secret}

${pdf_directory}            ${OUTPUT_DIR}${/}pdffolder${/}
${screenshot_directory}     ${OUTPUT_DIR}${/}imgfolder${/}
${zip_directory}             ${OUTPUT_DIR}${/}

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    website
    Log    ${secret}
    Log    Opening site ${secret}[value] 
    Open Available Browser    ${URL}    maximized=True

Get orders
    Download     https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=   Read table from CSV    orders.csv       
    RETURN       ${orders}

Close the modal
    Click Button    OK

Fill the form
    [Arguments]     ${row}
    Sleep    2s
    Select From List By Value    head        ${row}[Head]
    Select Radio Button     body    ${row}[Body]
    Input Text     //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text     //input[@placeholder="Shipping address"]    ${row}[Address] 

Preview the robot
    Click Button    Preview

Submit the order
    Log    submitting the order
    Wait Until Keyword Succeeds    
    ...    3x      
    ...    1s        
    ...    Click Button    Order
    Wait Until Page Contains    Receipt
    
Store the receipt as a PDF File
    [Arguments]     ${row} 
    Log    Storing receipt to pdf
    Wait Until Element Is Visible    receipt
    ${receipt_element} =    Get Element Attribute   //*[@id="receipt"]  outerHTML
    Log    ${receipt_element}
    Html To Pdf    content=${receipt_element}    output_path=${pdf_directory}${row}.pdf
    [Return]    ${pdf_directory}${row}.pdf

Take a screenshot of the robot
    [Arguments]     ${row}
    Log    Taking screenhot of the robot
    Capture Element Screenshot      //div[@id="robot-preview-image"]     ${screenshot_directory}${row}.png
    [Return]     ${screenshot_directory}${row}.png

 Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Log    opening pdf
    Open Pdf    ${pdf}
    Log    creating screenshot list        
    ${image_files} =    Create List    ${screenshot}:align=center
    Log    adding ${screenshot} to ${pdf}
    Add Files To PDF    ${image_files}    ${pdf}    append=FALSE
    Log    closing pdf
    Close Pdf    ${pdf}
  
Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    [Arguments]    ${name}
    ${name}=    Get Value From User    Give the zipfile name
    Create Directory    ${zip_directory}   
    Archive Folder With Zip    ${pdf_directory}    ${zip_directory}${name}

Close Browser and cleanup
    Close All Browsers

Create temp directories
    Create Directory    ${pdf_directory} 
    Create Directory    ${screenshot_directory} 
    