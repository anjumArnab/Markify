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

function doPost(e) {
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const data = JSON.parse(e.postData.contents);
  const action = data.action;

  switch (action) {
    case 'create':
      return createCourse(sheet, headers, data);
    case 'read':
      return readCourse(sheet, headers, data.courseName);
    case 'update':
      return updateCourse(sheet, headers, data);
    case 'delete':
      return deleteCourse(sheet, headers, data.courseName);
    default:
      return ContentService.createTextOutput(JSON.stringify({ status: 'error', message: 'Invalid action' })).setMimeType(ContentService.MimeType.JSON);
  }
}

function createCourse(sheet, headers, data) {
  const row = headers.map(header => data[header] || '');
  sheet.appendRow(row);
  return ContentService.createTextOutput(JSON.stringify({ status: 'success', message: 'Course added' })).setMimeType(ContentService.MimeType.JSON);
}

function readCourse(sheet, headers, courseName) {
  const data = sheet.getDataRange().getValues();
  const courseNameIndex = headers.indexOf('Course Name');
  const results = [];

  for (let i = 1; i < data.length; i++) {
    if (data[i][courseNameIndex] === courseName) {
      const record = {};
      headers.forEach((header, index) => {
        record[header] = data[i][index];
      });
      results.push(record);
    }
  }

  return ContentService.createTextOutput(JSON.stringify({ status: 'success', data: results })).setMimeType(ContentService.MimeType.JSON);
}

function updateCourse(sheet, headers, data) {
  const dataRange = sheet.getDataRange();
  const values = dataRange.getValues();
  const courseNameIndex = headers.indexOf('Course Name');

  for (let i = 1; i < values.length; i++) {
    if (values[i][courseNameIndex] === data['Course Name']) {
      headers.forEach((header, index) => {
        if (data[header] !== undefined && !['Grade Point', 'GPA', 'CGPA'].includes(header)) {
          sheet.getRange(i + 1, index + 1).setValue(data[header]);
        }
      });
      return ContentService.createTextOutput(JSON.stringify({ status: 'success', message: 'Course updated' })).setMimeType(ContentService.MimeType.JSON);
    }
  }

  return ContentService.createTextOutput(JSON.stringify({ status: 'error', message: 'Course not found' })).setMimeType(ContentService.MimeType.JSON);
}

function deleteCourse(sheet, headers, courseName) {
  const data = sheet.getDataRange().getValues();
  const courseNameIndex = headers.indexOf('Course Name');

  for (let i = 1; i < data.length; i++) {
    if (data[i][courseNameIndex] === courseName) {
      sheet.deleteRow(i + 1);
      return ContentService.createTextOutput(JSON.stringify({ status: 'success', message: 'Course deleted' })).setMimeType(ContentService.MimeType.JSON);
    }
  }

  return ContentService.createTextOutput(JSON.stringify({ status: 'error', message: 'Course not found' })).setMimeType(ContentService.MimeType.JSON);
}
