// EXPERIMENTAL VALIDATION ONLY. No product imports, persistence schema or production integration.
import AppKit
@preconcurrency import WebKit
import Foundation

@MainActor
final class Probe: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    var window: NSWindow!
    var retainedViews: [WKWebView] = []
    var pending: [ObjectIdentifier: CheckedContinuation<Void, Error>] = [:]
    var checks: [[String:Any]] = []
    var observations: [[String:Any]] = []
    let args=CommandLine.arguments
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("VX_BOOT disposable-native-harness"); fflush(stdout)
        window=NSWindow(contentRect:NSRect(x:0,y:0,width:240,height:120),styleMask:[.titled],backing:.buffered,defer:false)
        window.title="VX M1 disposable validation";window.contentView=NSView(frame:window.frame);window.orderFront(nil)
        DispatchQueue.main.asyncAfter(deadline:.now()+50) { self.finish(error:"bounded-timeout") }
        Task { @MainActor in
            do { try await self.run(); self.finish(error:nil) }
            catch { self.finish(error:String(describing:error)) }
        }
    }
    func check(_ name:String,_ passed:Bool) { checks.append(["observation":name,"passed":passed]) }
    func make(_ store:WKWebsiteDataStore)->WKWebView {
        let c=WKWebViewConfiguration();c.websiteDataStore=store
        let v=WKWebView(frame:NSRect(x:0,y:0,width:220,height:90),configuration:c)
        v.navigationDelegate=self;window.contentView!.addSubview(v);retainedViews.append(v);return v
    }
    func load(_ v:WKWebView,_ url:URL) async throws {
        try await withCheckedThrowingContinuation { (c:CheckedContinuation<Void,Error>) in
            pending[ObjectIdentifier(v)]=c;v.load(URLRequest(url:url))
        }
    }
    func webView(_ webView:WKWebView,didFinish navigation:WKNavigation!) {pending.removeValue(forKey:ObjectIdentifier(webView))?.resume()}
    func webView(_ webView:WKWebView,didFail navigation:WKNavigation!,withError error:Error) {pending.removeValue(forKey:ObjectIdentifier(webView))?.resume(throwing:error)}
    func webView(_ webView:WKWebView,didFailProvisionalNavigation navigation:WKNavigation!,withError error:Error) {pending.removeValue(forKey:ObjectIdentifier(webView))?.resume(throwing:error)}
    func js(_ v:WKWebView,_ body:String) async throws -> [String:Any] {
        let result:String = try await withCheckedThrowingContinuation { c in
            v.callAsyncJavaScript(body,arguments:[:],in:nil,in:.page) { result in
                switch result {
                case .success(let x): if let s=x as? String {c.resume(returning:s)} else {c.resume(throwing:NSError(domain:"fixture-result",code:1))}
                case .failure(let e):c.resume(throwing:e)
                }
            }
        }
        return try JSONSerialization.jsonObject(with:Data(result.utf8)) as! [String:Any]
    }
    func clear(_ s:WKWebsiteDataStore) async {await withCheckedContinuation { c in s.removeData(ofTypes:WKWebsiteDataStore.allWebsiteDataTypes(),modifiedSince:.distantPast){c.resume()} }}
    func remove(_ id:UUID) async -> String? {
        await withCheckedContinuation { c in WKWebsiteDataStore.remove(forIdentifier:id){e in c.resume(returning:e.map{String(describing:$0)})} }
    }
    func seed(_ v:WKWebView,_ marker:String) async throws -> [String:Any] {
        let body="""
        const marker='\(marker)'; const r={};
        document.cookie='vx_m1='+marker+'; Path=/; Max-Age=3600; SameSite=Lax';
        localStorage.setItem('vx_m1',marker);
        await new Promise((resolve,reject)=>{const q=indexedDB.open('vx_m1',1);q.onupgradeneeded=()=>q.result.createObjectStore('markers');q.onerror=()=>reject(q.error);q.onsuccess=()=>{const d=q.result;const t=d.transaction('markers','readwrite');t.objectStore('markers').put(marker,'value');t.oncomplete=()=>{d.close();resolve()};t.onerror=()=>reject(t.error)}});
        try {const c=await caches.open('vx_m1');await c.put('/synthetic-marker',new Response(marker));r.cacheSupported=true}catch(e){r.cacheSupported=false;r.cacheError=e.name}
        try {await navigator.serviceWorker.register('/sw.js');await Promise.race([navigator.serviceWorker.ready,new Promise((_,reject)=>setTimeout(()=>reject(new Error('worker-timeout')),8000))]);r.workerSupported=true}catch(e){r.workerSupported=false;r.workerError=e.name}
        return JSON.stringify(r);
        """
        return try await js(v,body)
    }
    func read(_ v:WKWebView) async throws -> [String:Any] {
        try await js(v,"""
        const r={cookie:document.cookie.split('; ').find(x=>x.startsWith('vx_m1='))?.split('=')[1]??null,local:localStorage.getItem('vx_m1')};
        r.idb=await new Promise((resolve,reject)=>{const q=indexedDB.open('vx_m1',1);q.onupgradeneeded=()=>q.result.createObjectStore('markers');q.onerror=()=>reject(q.error);q.onsuccess=()=>{const d=q.result,t=d.transaction('markers','readonly'),g=t.objectStore('markers').get('value');g.onsuccess=()=>resolve(g.result??null);g.onerror=()=>reject(g.error);t.oncomplete=()=>d.close()}});
        try {const m=await caches.match('/synthetic-marker');r.cache=m?await m.text():null}catch(e){r.cacheUnavailable=e.name}
        try {r.workers=(await navigator.serviceWorker.getRegistrations()).length}catch(e){r.workerUnavailable=e.name}
        return JSON.stringify(r);
        """)
    }
    func expect(_ label:String,_ values:[String:Any],_ marker:String?,_ capabilities:[String:Any]?=nil) {
        for key in ["cookie","local","idb"] {check(label+" "+key,marker == nil ? values[key] is NSNull : values[key] as? String == marker)}
        if capabilities?["cacheSupported"] as? Bool == true {check(label+" cache",marker == nil ? values["cache"] is NSNull : values["cache"] as? String == marker)}
        if capabilities?["workerSupported"] as? Bool == true {check(label+" service-worker",(values["workers"] as? Int ?? -1) == (marker == nil ? 0:1))}
        observations.append(["label":label,"values":values])
    }
    func privateProbe(_ url:URL) async throws {
        let p=WKWebsiteDataStore.nonPersistent(),q=WKWebsiteDataStore.nonPersistent()
        check("private stores nonpersistent",!p.isPersistent && !q.isPersistent)
        let p1=make(p),p2=make(p),q1=make(q)
        try await load(p1,url);let caps=try await seed(p1,"PRIVATE")
        try await load(p2,url);expect("private same-group",try await read(p2),"PRIVATE",caps)
        try await load(q1,url);expect("private independent-group",try await read(q1),nil,caps)
        for v in [p1,p2,q1] {v.stopLoading();v.removeFromSuperview();retainedViews.removeAll{$0 === v}}
        observations.append(["label":"private capability observations","values":caps])
    }
    func run() async throws {
        guard args.count==7,let aID=UUID(uuidString:args[2]),let bID=UUID(uuidString:args[3]),aID != bID,let url=URL(string:args[4]),let other=URL(string:args[5]) else {throw NSError(domain:"arguments",code:1)}
        let mode=args[1]
        if mode == "cleanup" {
            let ae=await remove(aID),be=await remove(bID)
            observations.append(["label":"post-exit-owned-store-removal","A":ae ?? "completed","B":be ?? "completed"])
            check("post-exit owned store removal completed",ae==nil && be==nil)
            return
        }
        let a=WKWebsiteDataStore(forIdentifier:aID),b=WKWebsiteDataStore(forIdentifier:bID)
        check("persistent stores persistent",a.isPersistent && b.isPersistent)
        let a1=make(a),a2=make(a),b1=make(b)
        if mode=="seed" {
            await clear(a);await clear(b)
            try await load(a1,url);let caps=try await seed(a1,"PROFILE_A")
            observations.append(["label":"persistent capability observations","values":caps])
            try await load(a2,url);expect("same-profile",try await read(a2),"PROFILE_A",caps)
            try await load(b1,url);expect("foreign-profile",try await read(b1),nil,caps)
            _=try await seed(b1,"PROFILE_B")
            try await load(a1,other);let cross=try await read(a1)
            for key in ["local","idb","cache"] {if cross[key] != nil {check("separate-origin "+key,cross[key] is NSNull)}}
            try await privateProbe(url)
            let fresh=make(.nonPersistent());try await load(fresh,url);expect("fresh-private-session",try await read(fresh),nil,caps)
        } else if mode=="verify" {
            try await load(a1,url);expect("relaunch A",try await read(a1),"PROFILE_A")
            try await load(b1,url);expect("relaunch B",try await read(b1),"PROFILE_B")
            await clear(a)
            let cleanA=make(a);try await load(cleanA,url);expect("scoped-delete A",try await read(cleanA),nil)
            expect("scoped-delete preserves B",try await read(b1),"PROFILE_B")
            for v in retainedViews {v.stopLoading();v.removeFromSuperview()};retainedViews.removeAll();window.close()
            let ae=await remove(aID),be=await remove(bID)
            observations.append(["label":"owned-store-removal","A":ae ?? "completed","B":be ?? "completed"])
            check("owned store removal completed",ae==nil && be==nil)
        } else {throw NSError(domain:"stage",code:1)}
    }
    func finish(error:String?) {
        var result:[String:Any]=["mode":args.count>1 ? args[1]:"unknown","checks":checks,"observations":observations,"productQualification":false,"platformQualification":false]
        if let error {result["error"]=error}
        if let data=try? JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),let s=String(data:data,encoding:.utf8){print("VX_RESULT "+s);fflush(stdout)}
        NSApplication.shared.terminate(nil)
    }
}
@main struct Entry {
    @MainActor static func main(){let app=NSApplication.shared;let delegate=Probe();app.delegate=delegate;app.setActivationPolicy(.accessory);withExtendedLifetime(delegate){app.run()}}
}

