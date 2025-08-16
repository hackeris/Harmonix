import { TermWebView } from "../pages/TermWebView"
import { TermController } from "./TermController"

let termId = 0

export class TermModel {
  controller: TermController
  view: TermWebView
  id: number

  constructor(close: (id: number) => void) {
    this.id = ++termId
    this.controller = new TermController(this.id, () => close(this.id))
    this.view = new TermWebView(this.controller)
  }
}