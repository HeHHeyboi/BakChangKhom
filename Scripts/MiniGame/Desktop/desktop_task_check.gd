class_name DesktopTaskCheck
## ตรวจงานบนจอ (ขมOS) ตอนกด "ลองใช้ให้ลูกค้าดู" — อ่านจาก DesktopTask + DesktopOS อย่างเดียว ไม่แตะ UI/คะแนน
## คะแนน (lose · _trap · notes) อยู่ที่ DesktopMinigameV2.check()


## "" = ผ่าน · ไม่ผ่าน = เหตุผลที่ลูกค้าบอก
static func reason(task: DesktopTask, os: DesktopOS) -> String:
	match task.goal:
		DesktopTask.Goal.INSTALL:
			if not os.installed_programs.has(task.install_name):
				return "ยังไม่มีโปรแกรม %s ในเครื่องเลย" % task.install_name
			if os.has_adware():
				return "เปิดเครื่องมามีโฆษณาเด้ง! มีโปรแกรมแถมติดมา ต้องถอนออกก่อน"
		DesktopTask.Goal.UNINSTALL:
			if os.has_adware():
				return "โฆษณายังเด้งอยู่เลย"
		DesktopTask.Goal.FREE_SPACE:
			for idx in os.dir_map[DesktopOS.TRASH].files:
				var f := os.fs[idx].data
				if f.kind == DesktopFile.USER:
					return "\"%s\" ของลูกค้าหายไปจากโฟลเดอร์! (อยู่ในถังขยะ)" % f.name
			if os.disk_free_mb < task.free_space_target_mb:
				return "ยังเซฟไม่ได้ พื้นที่เหลือ %s (ต้อง %s) — ลบแล้วอย่าลืมล้างถังขยะ" % [
					DesktopOS.size_text(os.disk_free_mb),
					DesktopOS.size_text(task.free_space_target_mb),
				]
		DesktopTask.Goal.CLOSE_HANG:
			for pid in os.process_map:
				var p := os.process_map[pid]
				if p.data.kind == "hang":
					return "\"%s\" ยังค้างอยู่เลย กดอะไรก็ไม่ขยับ" % p.data.name
		DesktopTask.Goal.STARTUP:
			for pid in os.autostart_map:
				var p := os.autostart_map[pid]
				if p.data.kind == "system" and not p.autostart:
					return "%s ไม่เปิดพร้อมเครื่อง เครื่องไม่ปลอดภัย" % p.data.name
			if os.boot_time() > task.boot_target_s:
				return "เปิดเครื่องยังช้าอยู่ (~%d วินาที) ลูกค้ารอนานเกิน" % os.boot_time()
		DesktopTask.Goal.PRINTER:
			var pr = os.printer_map.get(os.printer_default_index) as DesktopOS.Printer
			if pr == null:
				return "ยังพิมพ์ไม่ได้ ไม่มีเครื่องพิมพ์ในเครื่อง"
			if not pr.data.right:
				return "สั่งพิมพ์แล้วไปออกที่เครื่อง \"%s\"" % pr.data.name
			if not os.printed_ok:
				return "ยังไม่ได้ลองพิมพ์หน้าทดสอบเลย"
		DesktopTask.Goal.SOUND:
			var res := os.test_sound()
			if not res.begins_with("♪"):
				return "เปิดเพลงแล้วยังเงียบ — " + res
		DesktopTask.Goal.WIFI:
			if os.connected_network < 0:
				return "ยังเข้าเน็ตไม่ได้เลย"
			if not os.wifi_detected[os.connected_network].data.right:
				return "เข้าเน็ตได้ แต่เป็นเน็ตสาธารณะ ไม่ใช่เน็ตบ้านลูกค้า"
		DesktopTask.Goal.BACKUP:
			var miss: PackedStringArray = []
			for f in task.files:
				if f.folder_name() != task.backup_folder or f.kind != DesktopFile.USER:
					continue
				if not (os.find_file(f.name, task.backup_folder) and os.find_file(f.name, DesktopTask.USB)):
					miss.append(f.name)
			if not miss.is_empty():
				return "รูปยังไม่ครบสองที่ (ในเครื่อง + USB): %s" % ", ".join(miss)
			if not os.usb_ejected:
				return "ยังไม่ได้กด \"ถอด USB อย่างปลอดภัย\" ดึงออกเลยไฟล์อาจเสีย"
		DesktopTask.Goal.UPDATE:
			if os.update_state == DesktopOS.UpdateState.RESTART:
				return "ติดตั้งแล้วแต่ยังไม่ได้รีสตาร์ต"
			if os.update_state != DesktopOS.UpdateState.FINISH:
				return "เครื่องยังไม่ได้อัปเดต"
		DesktopTask.Goal.VIRUS_SCAN:
			if not os.protection_on:
				return "การป้องกันไวรัสถูกปิดอยู่ เครื่องไม่ปลอดภัย"
			for t in os.threats:
				if t.state != DesktopOS.ThreatState.QUARANTINE:
					return "ยังมีไวรัสอยู่ในเครื่อง (สแกนแล้วกักกันให้หมด)"
			if task.temp_mb > 0 and os.disk_temp_mb > 0:
				return "ยังอืดอยู่ ไฟล์ชั่วคราวเต็มเครื่อง"
		DesktopTask.Goal.DISPLAY:
			if os.pending_resolution >= 0:
				return "จอดำอยู่!"
			if not task.resolutions.is_empty():
				var scale_ok: bool = os.selected_scale >= 0 and os.scale_list[os.selected_scale] == task.display_scale_best
				if not task.resolutions[os.selected_resolution].best or not scale_ok:
					return "จอยังดูแปลก ๆ ตัวหนังสือใหญ่/แตกอยู่"
	return ""
