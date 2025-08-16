import { TermWebView } from "../pages/TermWebView"
import { TermController } from "./TermController"

export class TermModel {
  controller: TermController
  view: TermWebView
  id: number
  
  constructor(close: () => void) {
    this.controller = new TermController(close)
    this.id = this.controller.id
    this.view = new TermWebView(this.controller)
  }
}