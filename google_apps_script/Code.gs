/**
 * Student Queue Management System - Google Apps Script Backend
 * ============================================================
 * Instructions:
 * 1. Open Google Sheets -> Extensions -> Apps Script.
 * 2. Replace all code in Code.gs with this script.
 * 3. Deploy as Web App:
 *    - Execute as: Me (your Google account)
 *    - Who has access: Anyone
 * 4. Copy the Web App URL and paste it in the Flutter App Settings.
 */

// Global Constants
const SHEET_ACTIVE = "Active";
const SHEET_COMPLETED = "Completed";

// Headers for sheets
const HEADERS = [
  "id",
  "name",
  "doctor",
  "status",
  "paperStatus",
  "registrationTime",
  "calledTime",
  "completionTime"
];

/**
 * Initializes sheets if they don't exist.
 */
function initSheets() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  
  let activeSheet = ss.getSheetByName(SHEET_ACTIVE);
  if (!activeSheet) {
    activeSheet = ss.insertSheet(SHEET_ACTIVE);
    activeSheet.appendRow(HEADERS);
    activeSheet.getRange(1, 1, 1, HEADERS.length).setFontWeight("bold").setBackground("#e0f2fe");
  }
  
  let completedSheet = ss.getSheetByName(SHEET_COMPLETED);
  if (!completedSheet) {
    completedSheet = ss.insertSheet(SHEET_COMPLETED);
    completedSheet.appendRow(HEADERS);
    completedSheet.getRange(1, 1, 1, HEADERS.length).setFontWeight("bold").setBackground("#f1f5f9");
  }
}

/**
 * GET Handler - Returns active and completed queues
 */
function doGet(e) {
  try {
    initSheets();
    const active = getSheetData(SHEET_ACTIVE);
    const completed = getSheetData(SHEET_COMPLETED);
    
    return responseJSON({
      success: true,
      status: "success",
      data: {
        active: active,
        completed: completed
      },
      active: active,
      completed: completed
    });
  } catch (error) {
    return responseJSON({
      success: false,
      status: "error",
      message: error.toString()
    });
  }
}

/**
 * POST Handler - Processes actions
 */
function doPost(e) {
  try {
    initSheets();
    let body = {};
    
    if (e && e.postData && e.postData.contents) {
      body = JSON.parse(e.postData.contents);
    } else if (e && e.parameter) {
      body = e.parameter;
    }
    
    const action = body.action;
    
    if (!action) {
      return responseJSON({ success: false, status: "error", message: "Missing action parameter" });
    }
    
    switch (action) {
      case "addStudent":
        return handleAddStudent(body);
      case "updateStatus":
        return handleUpdateStatus(body);
      case "setPaperReady":
        return handleSetPaperReady(body);
      case "sendToAdvising":
        return handleSendToAdvising(body);
      case "completeService":
        return handleCompleteService(body);
      default:
        return responseJSON({ success: false, status: "error", message: "Invalid action: " + action });
    }
  } catch (error) {
    return responseJSON({
      success: false,
      status: "error",
      message: error.toString()
    });
  }
}

/**
 * Helper: Formats response as JSON
 */
function responseJSON(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

/**
 * Helper: Reads rows from a sheet as JSON objects
 */
function getSheetData(sheetName) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) return [];
  
  const lastRow = sheet.getLastRow();
  if (lastRow <= 1) return []; // Only headers or empty
  
  const values = sheet.getRange(2, 1, lastRow - 1, HEADERS.length).getValues();
  return values.map(row => {
    return {
      id: String(row[0]),
      name: String(row[1]),
      doctor: String(row[2]),
      status: String(row[3]),
      paperStatus: String(row[4]),
      registrationTime: String(row[5]),
      calledTime: String(row[6]),
      completionTime: String(row[7])
    };
  });
}

/**
 * Action: Add New Student
 */
function handleAddStudent(data) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_ACTIVE);
  
  const now = new Date();
  const timestampStr = Utilities.formatDate(now, Session.getScriptTimeZone(), "yyyy-MM-dd HH:mm:ss");
  
  const studentId = "STU-" + now.getTime().toString().slice(-6) + "-" + Math.floor(1000 + Math.random() * 9000);
  const name = data.name || "";
  const doctor = data.doctor || "";
  const paperStatus = data.paperStatus || "PENDING";
  
  let status = "WAITING";
  if (paperStatus === "PENDING" || paperStatus === "ناقصة") {
    status = "PENDING_PAPERS";
  }
  
  const newRow = [
    studentId,
    name,
    doctor,
    status,
    paperStatus === "READY" ? "READY" : "PENDING",
    timestampStr,
    "", // calledTime
    ""  // completionTime
  ];
  
  sheet.appendRow(newRow);
  
  return responseJSON({
    success: true,
    status: "success",
    message: "Student added successfully",
    student: {
      id: studentId,
      name: name,
      doctor: doctor,
      status: status,
      paperStatus: paperStatus === "READY" ? "READY" : "PENDING",
      registrationTime: timestampStr,
      calledTime: "",
      completionTime: ""
    }
  });
}

/**
 * Action: Update Student Status
 */
function handleUpdateStatus(data) {
  const studentId = data.id;
  const newStatus = data.newStatus || data.status;
  
  if (!studentId || !newStatus) {
    return responseJSON({ success: false, status: "error", message: "Missing id or status" });
  }
  
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_ACTIVE);
  const lastRow = sheet.getLastRow();
  
  if (lastRow <= 1) {
    return responseJSON({ success: false, status: "error", message: "Student not found" });
  }
  
  const ids = sheet.getRange(2, 1, lastRow - 1, 1).getValues();
  let rowIndex = -1;
  
  for (let i = 0; i < ids.length; i++) {
    if (String(ids[i][0]) === String(studentId)) {
      rowIndex = i + 2;
      break;
    }
  }
  
  if (rowIndex === -1) {
    return responseJSON({ success: false, status: "error", message: "Student ID not found in Active queue" });
  }
  
  const now = new Date();
  const timeStr = Utilities.formatDate(now, Session.getScriptTimeZone(), "yyyy-MM-dd HH:mm:ss");
  
  // Update status in column 4 (D)
  sheet.getRange(rowIndex, 4).setValue(String(newStatus));
  
  // Update timestamps based on status
  if (newStatus === "IN_PROGRESS" || newStatus === "IN_ADVISING") {
    sheet.getRange(rowIndex, 7).setValue(timeStr); // calledTime (Col G)
  }
  
  return responseJSON({
    success: true,
    status: "success",
    message: "Status updated to " + newStatus
  });
}

/**
 * Action: Promote Pending Papers to WAITING
 */
function handleSetPaperReady(data) {
  const studentId = data.id;
  if (!studentId) {
    return responseJSON({ success: false, status: "error", message: "Missing student ID" });
  }
  
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_ACTIVE);
  const lastRow = sheet.getLastRow();
  
  if (lastRow <= 1) return responseJSON({ success: false, status: "error", message: "Student not found" });
  
  const ids = sheet.getRange(2, 1, lastRow - 1, 1).getValues();
  let rowIndex = -1;
  
  for (let i = 0; i < ids.length; i++) {
    if (String(ids[i][0]) === String(studentId)) {
      rowIndex = i + 2;
      break;
    }
  }
  
  if (rowIndex === -1) {
    return responseJSON({ success: false, status: "error", message: "Student ID not found" });
  }
  
  sheet.getRange(rowIndex, 4).setValue("WAITING"); // status -> WAITING
  sheet.getRange(rowIndex, 5).setValue("READY");   // paperStatus -> READY
  
  return responseJSON({
    success: true,
    status: "success",
    message: "Paper marked READY. Student status promoted to WAITING."
  });
}

/**
 * Action: Send Student to Academic Advising
 */
function handleSendToAdvising(data) {
  data.status = "WAITING_ADVISING";
  data.newStatus = "WAITING_ADVISING";
  return handleUpdateStatus(data);
}

/**
 * Action: Complete Service (Moves row to Completed sheet)
 */
function handleCompleteService(data) {
  const studentId = data.id;
  const finalStatus = data.newStatus || data.status || "DONE";
  
  if (!studentId) {
    return responseJSON({ success: false, status: "error", message: "Missing student ID" });
  }
  
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const activeSheet = ss.getSheetByName(SHEET_ACTIVE);
  const completedSheet = ss.getSheetByName(SHEET_COMPLETED);
  
  const lastRow = activeSheet.getLastRow();
  if (lastRow <= 1) return responseJSON({ success: false, status: "error", message: "Student not found" });
  
  const ids = activeSheet.getRange(2, 1, lastRow - 1, 1).getValues();
  let rowIndex = -1;
  
  for (let i = 0; i < ids.length; i++) {
    if (String(ids[i][0]) === String(studentId)) {
      rowIndex = i + 2;
      break;
    }
  }
  
  if (rowIndex === -1) {
    return responseJSON({ success: false, status: "error", message: "Student ID not found in Active queue" });
  }
  
  const rowData = activeSheet.getRange(rowIndex, 1, 1, HEADERS.length).getValues()[0];
  
  const now = new Date();
  const completionTime = Utilities.formatDate(now, Session.getScriptTimeZone(), "yyyy-MM-dd HH:mm:ss");
  
  rowData[3] = String(finalStatus);  // status
  rowData[7] = completionTime;        // completionTime
  
  // Append to completed sheet
  completedSheet.appendRow(rowData);
  
  // Delete row from active sheet
  activeSheet.deleteRow(rowIndex);
  
  return responseJSON({
    success: true,
    status: "success",
    message: "Service completed and student archived successfully"
  });
}
