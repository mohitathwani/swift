func funcWithParamsNoReturnThrow(_ a: Int, b: Int, c: String) throws {
    
}

// RUN: %empty-directory(%t.result)
// RUN: %refactor -doc-comment-boilerplate -source-filename %s -pos=1:7 > %t.result/with_parameters_throw.swift
// RUN: diff -u %S/Outputs/with_parameters_throw/with_parameters_throw.swift.expected %t.result/with_parameters_throw.swift
