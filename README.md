# Markify

Markify is a lightweight Flutter app that tracks your CGPA using **Google Sheets** as a backend database, with **Google Apps Script** providing a RESTful API interface. 

## Technology Stack

- **Flutter**: Client-side app for UI and API communication
- **Google Sheets**: Cloud spreadsheet database for student records
- **Google Apps Script**: Backend REST API layer deployed as a Web App

---

## Script for `code.gs`

```javascript
const SHEET_ID = '';
const SHEET_NAME = '';

const gradeMap = {
  "A+": 4.0, "A": 4.0,
  "A-": 3.7, "B+": 3.3,
  "B": 3.0, "B-": 2.7,
  "C+": 2.3, "C": 2.0,
  "C-": 1.7, "D": 1.0,
  "F": 0.0
};

function getSheet() {
  return SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
}

// READ: Get all courses + calculated CGPA
function doGet(e) {
  const sheet = getSheet();
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const rows = data.slice(1);

  let totalPoints = 0;
  let totalCredits = 0;

  const courses = rows
    .filter(row => row[0] !== '') // skip empty rows
    .map(row => {
      const id = row[0];
      const semester = row[1];
      const courseName = row[2];
      const grade = row[3];
      const creditHours = Number(row[4]);
      const gradePoint = gradeMap[grade] || 0;
      const earned = gradePoint * creditHours;

      totalPoints += earned;
      totalCredits += creditHours;

      return {
        id,
        semester,
        courseName,
        grade,
        creditHours,
        gradePoint
      };
    });

  const cgpa = totalCredits > 0 ? (totalPoints / totalCredits).toFixed(2) : "0.00";

  return ContentService.createTextOutput(
    JSON.stringify({ cgpa, courses })
  ).setMimeType(ContentService.MimeType.JSON);
}

// CREATE: Add a new course
function doPost(e) {
  const sheet = getSheet();
  const body = JSON.parse(e.postData.contents);

  const id = Utilities.getUuid();
  const semester = body.semester;
  const courseName = body.courseName;
  const grade = body.grade;
  const creditHours = Number(body.creditHours);
  const gradePoint = gradeMap[grade] || 0;

  sheet.appendRow([id, semester, courseName, grade, creditHours, gradePoint]);

  return ContentService.createTextOutput(
    JSON.stringify({ status: "success", id })
  ).setMimeType(ContentService.MimeType.JSON);
}

// UPDATE: Modify a course by ID
function doPut(e) {
  const sheet = getSheet();
  const body = JSON.parse(e.postData.contents);

  const id = body.id;
  const rows = sheet.getDataRange().getValues();

  for (let i = 1; i < rows.length; i++) {
    if (rows[i][0] === id) {
      const gradePoint = gradeMap[body.grade] || 0;
      sheet.getRange(i + 1, 2, 1, 5).setValues([[
        body.semester,
        body.courseName,
        body.grade,
        Number(body.creditHours),
        gradePoint
      ]]);
      return ContentService.createTextOutput(JSON.stringify({ status: "updated" }))
        .setMimeType(ContentService.MimeType.JSON);
    }
  }

  return ContentService.createTextOutput(JSON.stringify({ status: "not_found" }))
    .setMimeType(ContentService.MimeType.JSON);
}

// DELETE: Remove a course by ID
function doDelete(e) {
  const id = e.parameter.id;
  const sheet = getSheet();
  const rows = sheet.getDataRange().getValues();

  for (let i = 1; i < rows.length; i++) {
    if (rows[i][0] === id) {
      sheet.deleteRow(i + 1);
      return ContentService.createTextOutput(JSON.stringify({ status: "deleted" }))
        .setMimeType(ContentService.MimeType.JSON);
    }
  }

  return ContentService.createTextOutput(JSON.stringify({ status: "not_found" }))
    .setMimeType(ContentService.MimeType.JSON);
}

