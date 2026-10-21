# Redmine Move Comments

Verschiebt einzelne Kommentare (Journals) von einem Ticket in ein anderes. Beim Verschieben wird im Zielticket ein neues Journal angelegt, Anhänge und deren Journal-Details werden umgehängt, anschließend wird das Quell-Journal gelöscht (bzw. nur die Notiz entfernt, falls noch andere Änderungsdetails daran hängen). Nach jedem Move wird der Hook `:move_comments_after_journal_move` mit `source_journal`, `new_journal` und `target_issue` aufgerufen.

## Zusammenspiel mit anderen Plugins

- **redmine_sendmail**: Zeilen aus `RedmineSendmailDispatch` (Versand-Badges) werden vor dem Löschen des Quell-Journals auf das neue Journal/Ticket umgehängt.
- **redmine_mail_handler**: Kommentare, die aus einer eingegangenen E-Mail erzeugt wurden, sind über eine Zeile in `mail_handler_journal_mails` (Modell `MailHandlerJournalMail`, verknüpft nur per `journal_id`, kein Fremdschlüssel) markiert. Diese Marker-Zeile wird beim Verschieben ebenfalls vor dem Löschen des Quell-Journals auf das neue Journal und das Zielticket umgeschrieben, damit die Information „stammt aus einer Mail“ (inkl. Message-ID, Absender, Betreff) am verschobenen Kommentar erhalten bleibt. Der Schritt ist defensiv: Fehlt das Plugin oder die Tabelle, wird er übersprungen; ein Fehler dabei wird nur geloggt und bricht den Move nicht ab.
