// RUN: %target-swift-frontend(mock-sdk: %clang-importer-sdk) -emit-silgen -I %S/Inputs/custom-modules -enable-experimental-concurrency %s -verify | %FileCheck --check-prefix=CHECK --check-prefix=CHECK-%target-cpu %s
// REQUIRES: objc_interop

import Foundation
import ObjCConcurrency

@objc protocol SlowServing {
    func requestInt() async -> Int
    func requestString() async -> String
    func tryRequestString() async throws -> String
    func requestIntAndString() async -> (Int, String)
    func tryRequestIntAndString() async throws -> (Int, String)
}

// CHECK-LABEL: sil {{.*}}@{{.*}}15testSlowServing
func testSlowServing(p: SlowServing) async throws {
    // CHECK: objc_method {{.*}} $@convention(objc_method) <τ_0_0 where τ_0_0 : SlowServing> (@convention(block) (Int) -> (), τ_0_0) -> ()
    let _: Int = await p.requestInt()
    // CHECK: objc_method {{.*}} $@convention(objc_method) <τ_0_0 where τ_0_0 : SlowServing> (@convention(block) (NSString) -> (), τ_0_0) -> ()
    let _: String = await p.requestString()
    // CHECK: objc_method {{.*}} $@convention(objc_method) <τ_0_0 where τ_0_0 : SlowServing> (@convention(block) (Optional<NSString>, Optional<NSError>) -> (), τ_0_0) -> ()
    let _: String = await try p.tryRequestString()
    // CHECK: objc_method {{.*}} $@convention(objc_method) <τ_0_0 where τ_0_0 : SlowServing> (@convention(block) (Int, NSString) -> (), τ_0_0) -> ()
    let _: (Int, String) = await p.requestIntAndString()
    // CHECK: objc_method {{.*}} $@convention(objc_method) <τ_0_0 where τ_0_0 : SlowServing> (@convention(block) (Int, Optional<NSString>, Optional<NSError>) -> (), τ_0_0) -> ()
    let _: (Int, String) = await try p.tryRequestIntAndString()
}

class SlowSwiftServer: NSObject, SlowServing {
    // CHECK-LABEL: sil {{.*}} @${{.*}}10requestInt{{.*}}To :
    // CHECK:         [[BLOCK_COPY:%.*]] = copy_value %0
    // CHECK:         [[SELF:%.*]] = copy_value %1
    // CHECK:         [[CLOSURE_REF:%.*]] = function_ref [[CLOSURE_IMP:@\$.*10requestInt.*U_To]] :
    // CHECK:         [[CLOSURE:%.*]] = partial_apply [callee_guaranteed] [[CLOSURE_REF]]([[BLOCK_COPY]], [[SELF]])
    // CHECK:         [[RUN_TASK:%.*]] = function_ref @${{.*}}29_runTaskForBridgedAsyncMethod
    // CHECK:         apply [[RUN_TASK]]([[CLOSURE]])
    // CHECK:       sil {{.*}} [[CLOSURE_IMP]]
    // CHECK:         [[NATIVE_RESULT:%.*]] = apply{{.*}}@async
    // CHECK:         apply %0([[NATIVE_RESULT]])
    func requestInt() async -> Int { return 0 }
    func requestString() async -> String { return "" }
    // CHECK-LABEL: sil {{.*}} @${{.*}}16tryRequestString{{.*}}U_To :
    // CHECK:         try_apply{{.*}}@async{{.*}}, normal [[NORMAL:bb[0-9]+]], error [[ERROR:bb[0-9]+]]
    // CHECK:       [[NORMAL]]([[NATIVE_RESULT:%.*]] : @owned $String):
    // CHECK:         [[NIL_ERROR:%.*]] = enum $Optional<NSError>, #Optional.none
    // CHECK:         apply %0({{%.*}}, [[NIL_ERROR]])
    // CHECK:       [[ERROR]]([[NATIVE_RESULT:%.*]] : @owned $Error):
    // CHECK:         [[NIL_NSSTRING:%.*]] = enum $Optional<NSString>, #Optional.none
    // CHECK:         apply %0([[NIL_NSSTRING]], {{%.*}})
    func tryRequestString() async throws -> String { return "" }
    func requestIntAndString() async -> (Int, String) { return (0, "") }
    func tryRequestIntAndString() async throws -> (Int, String) { return (0, "") }
}


protocol NativelySlowServing {
    func doSomethingSlow(_: String) async -> Int
    func findAnswer() async throws -> String
    func serverRestart(_: String) async
    func findMultipleAnswers() async throws -> (String, Int)
}

extension SlowServer: NativelySlowServing {}
