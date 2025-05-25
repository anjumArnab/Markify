# Markify

Markify is a lightweight Flutter app that tracks your CGPA using **Google Sheets** as a backend database, with **Google Apps Script** providing a RESTful API interface. 

## Technology Stack

- **Flutter**: Client-side app for UI and API communication
- **Google Sheets**: Cloud spreadsheet database for student records
- **Google Apps Script**: Backend REST API layer deployed as a Web App

---

## Script for `code.gs`

```javascript
// Configuration constants
const SHEET_ID = "";
const SHEET_NAME = "";

/**
 * Initializes the spreadsheet with headers if they don't exist
 */
function initializeSpreadsheet() {
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  
  // Check if sheet is empty or has no data
  if (sheet.getLastRow() === 0) {
    // Create header row
    sheet.appendRow(["Semester", "Course", "Grade", "Credit Hours", "GPA", "CGPA"]);
    
    // Format the header row
    sheet.getRange(1, 1, 1, 6).setFontWeight("bold");
    sheet.getRange(1, 1, 1, 6).setBackground("#f3f3f3");
    
    // Set formulas for GPA and CGPA (these will be empty until data is added)
    // These are placeholders as the actual formulas depend on calculation method
    
    return true;
  }
  
  return false;
}

/**
 * Handles GET requests to retrieve all academic records
 */
function doGet(e) {
  try {
    // Check if an ID is provided for a single record
    if (e.parameter && e.parameter.id) {
      return getRecordById(parseInt(e.parameter.id));
    }
    
    // Check if a semester filter is provided
    if (e.parameter && e.parameter.semester) {
      return getRecordsBySemester(e.parameter.semester);
    }
    
    const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
    
    // Initialize spreadsheet if needed
    const initialized = initializeSpreadsheet();
    
    const values = sheet.getDataRange().getValues();
    const records = [];
    
    // If sheet was just initialized or has only headers, return empty array
    if (values.length <= 1) {
      return ContentService.createTextOutput(JSON.stringify({
        status: "SUCCESS",
        data: []
      }))
      .setMimeType(ContentService.MimeType.JSON);
    }
    
    // Skip header row and process data
    for (let i = 1; i < values.length; i++) {
      const row = values[i];
      records.push({
        id: i, // ID based on row index
        semester: row[0]?.toString() || "",
        course: row[1]?.toString() || "",
        grade: row[2]?.toString() || "",
        creditHours: parseFloat(row[3]) || 0,
        gpa: parseFloat(row[4]) || 0,  // GPA is calculated in spreadsheet
        cgpa: parseFloat(row[5]) || 0  // CGPA is calculated in spreadsheet
      });
    }
    
    return ContentService.createTextOutput(JSON.stringify({
      status: "SUCCESS",
      data: records
    }))
    .setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    return handleError(error, "Error retrieving academic records");
  }
}

/**
 * Get a specific record by ID
 */
function getRecordById(id) {
  try {
    if (isNaN(id) || id < 1) {
      return handleError(null, "Invalid ID. Must be a positive number");
    }
    
    const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
    const rowIndex = id + 1; // Account for header row
    
    // Check if row exists
    if (rowIndex > sheet.getLastRow()) {
      return handleError(null, "Record ID not found");
    }
    
    const rowData = sheet.getRange(rowIndex, 1, 1, 6).getValues()[0];
    
    const record = {
      id: id,
      semester: rowData[0]?.toString() || "",
      course: rowData[1]?.toString() || "",
      grade: rowData[2]?.toString() || "",
      creditHours: parseFloat(rowData[3]) || 0,
      gpa: parseFloat(rowData[4]) || 0,
      cgpa: parseFloat(rowData[5]) || 0
    };
    
    return ContentService.createTextOutput(JSON.stringify({
      status: "SUCCESS",
      data: record
    }))
    .setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    return handleError(error, "Error retrieving record");
  }
}

/**
 * Get records filtered by semester
 */
function getRecordsBySemester(semester) {
  try {
    const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
    const values = sheet.getDataRange().getValues();
    const records = [];
    
    // Skip header row and filter by semester
    for (let i = 1; i < values.length; i++) {
      const row = values[i];
      if (row[0]?.toString().toLowerCase() === semester.toLowerCase()) {
        records.push({
          id: i,
          semester: row[0]?.toString() || "",
          course: row[1]?.toString() || "",
          grade: row[2]?.toString() || "",
          creditHours: parseFloat(row[3]) || 0,
          gpa: parseFloat(row[4]) || 0,
          cgpa: parseFloat(row[5]) || 0
        });
      }
    }
    
    return ContentService.createTextOutput(JSON.stringify({
      status: "SUCCESS",
      data: records
    }))
    .setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    return handleError(error, "Error retrieving records by semester");
  }
}

/**
 * Handles POST requests for create, update, and delete operations
 */
function doPost(e) {
  try {
    if (!e.parameter || !e.parameter.action) {
      return handleError(null, "Missing 'action' parameter");
    }
    
    const action = e.parameter.action;
    
    switch (action) {
      case "create":
        return createRecord(e);
      case "update":
        return updateRecord(e);
      case "delete":
        return deleteRecord(e);
      default:
        return handleError(null, "Invalid action. Must be 'create', 'update', or 'delete'");
    }
  } catch (error) {
    return handleError(error, "Error processing request");
  }
}

/**
 * Creates a new academic record
 * Note: GPA and CGPA will be calculated by spreadsheet formulas
 */
function createRecord(e) {
  try {
    // Validate required inputs
    if (!e.parameter.semester || !e.parameter.course || !e.parameter.grade || !e.parameter.creditHours) {
      return handleError(null, "Missing required fields (semester, course, grade, creditHours)");
    }
    
    const semester = e.parameter.semester;
    const course = e.parameter.course;
    const grade = e.parameter.grade;
    const creditHours = parseFloat(e.parameter.creditHours);
    
    // Validate credit hours
    if (isNaN(creditHours) || creditHours <= 0) {
      return handleError(null, "Credit Hours must be a positive number");
    }
    
    const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
    
    // Initialize spreadsheet if needed
    initializeSpreadsheet();
    
    // For GPA and CGPA columns, we leave them empty or add placeholder values
    // These will be calculated by Google Sheet formulas
    sheet.appendRow([semester, course, grade, creditHours, "", ""]);
    
    return ContentService.createTextOutput(JSON.stringify({
      status: "SUCCESS",
      message: "Academic record created successfully"
    }))
    .setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    return handleError(error, "Error creating academic record");
  }
}

/**
 * Updates an existing academic record
 * Note: Only updates Semester, Course, Grade, and Credit Hours fields
 * GPA and CGPA are calculated by spreadsheet formulas
 */
function updateRecord(e) {
  try {
    const id = parseInt(e.parameter.id);
    
    // Validate ID
    if (isNaN(id) || id < 1) {
      return handleError(null, "Invalid ID. Must be a positive number");
    }
    
    const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
    
    // Initialize spreadsheet if needed
    const wasInitialized = initializeSpreadsheet();
    if (wasInitialized) {
      return handleError(null, "No records exist yet. Sheet was just initialized with headers.");
    }
    
    const rowIndex = id + 1; // Account for header row
    
    // Check if row exists
    if (rowIndex > sheet.getLastRow()) {
      return handleError(null, "Record ID not found");
    }
    
    // Get current values to update only provided fields
    const currentValues = sheet.getRange(rowIndex, 1, 1, 4).getValues()[0];
    
    const semester = e.parameter.semester !== undefined ? e.parameter.semester : currentValues[0];
    const course = e.parameter.course !== undefined ? e.parameter.course : currentValues[1];
    const grade = e.parameter.grade !== undefined ? e.parameter.grade : currentValues[2];
    let creditHours = currentValues[3];
    
    if (e.parameter.creditHours !== undefined) {
      creditHours = parseFloat(e.parameter.creditHours);
      // Validate credit hours if provided
      if (isNaN(creditHours) || creditHours <= 0) {
        return handleError(null, "Credit Hours must be a positive number");
      }
    }
    
    // Update only the user-editable fields (Not GPA and CGPA which are calculated)
    sheet.getRange(rowIndex, 1).setValue(semester);
    sheet.getRange(rowIndex, 2).setValue(course);
    sheet.getRange(rowIndex, 3).setValue(grade);
    sheet.getRange(rowIndex, 4).setValue(creditHours);
    
    // Note: No need to update GPA and CGPA as they are calculated by formulas in the spreadsheet
    
    return ContentService.createTextOutput(JSON.stringify({
      status: "SUCCESS",
      message: "Academic record updated successfully"
    }))
    .setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    return handleError(error, "Error updating academic record");
  }
}

/**
 * Deletes an academic record
 */
function deleteRecord(e) {
  try {
    const id = parseInt(e.parameter.id);
    
    // Validate ID
    if (isNaN(id) || id < 1) {
      return handleError(null, "Invalid ID. Must be a positive number");
    }
    
    const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
    
    // Initialize spreadsheet if needed
    const wasInitialized = initializeSpreadsheet();
    if (wasInitialized) {
      return handleError(null, "No records exist yet. Sheet was just initialized with headers.");
    }
    
    const rowIndex = id + 1; // Account for header row
    
    // Check if row exists
    if (rowIndex > sheet.getLastRow()) {
      return handleError(null, "Record ID not found");
    }
    
    sheet.deleteRow(rowIndex);
    
    return ContentService.createTextOutput(JSON.stringify({
      status: "SUCCESS",
      message: "Academic record deleted successfully"
    }))
    .setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    return handleError(error, "Error deleting academic record");
  }
}

/**
 * Helper function to handle errors consistently
 */
function handleError(error, message) {
  console.error(error); // Log the error for debugging
  
  return ContentService.createTextOutput(JSON.stringify({
    status: "ERROR",
    message: message,
    details: error ? error.toString() : null
  }))
  .setMimeType(ContentService.MimeType.JSON);
}

## Google Sheet Functions
For GPA calculation
```
=IF(A2="", "", LET(
  sem, A2,
  grades, FILTER(C$2:C, A$2:A=sem),
  credits, FILTER(D$2:D, A$2:A=sem),
  points, MAP(grades, LAMBDA(g,
    SWITCH(g,
      "A+", 4.00,
      "A", 3.75,
      "A-", 3.50,
      "B+", 3.25,
      "B", 3.00,
      "B-", 2.75,
      "C+", 2.50,
      "C", 2.25,
      "D", 2.00,
      "F", 0,
      0)
  )),
  totalPoints, SUM(MAP(points, credits, LAMBDA(p, c, p * c))),
  totalCredits, SUM(credits),
  IF(totalCredits = 0, "", ROUND(totalPoints / totalCredits, 2))
))
```

For CGPA Calculation
```
=IF(COUNT(E2:E) = 0, 0, SUM(E2:E)/COUNT(E2:E))
```