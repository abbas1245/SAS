import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="admin-users"
export default class extends Controller {
  static targets = ["roleSelection", "teacherForm", "studentForm"]

  connect() {
    console.log("Admin Users controller connected")
  }

  selectTeacher(event) {
    event.preventDefault()
    console.log("Selecting teacher form")
    this.roleSelectionTarget.classList.add("hidden")
    this.studentFormTarget.classList.add("hidden")
    this.teacherFormTarget.classList.remove("hidden")
  }

  selectStudent(event) {
    event.preventDefault()
    console.log("Selecting student form")
    this.roleSelectionTarget.classList.add("hidden")
    this.teacherFormTarget.classList.add("hidden")
    this.studentFormTarget.classList.remove("hidden")
  }

  goBack(event) {
    event.preventDefault()
    console.log("Going back to role selection")
    this.teacherFormTarget.classList.add("hidden")
    this.studentFormTarget.classList.add("hidden")
    this.roleSelectionTarget.classList.remove("hidden")
  }
} 