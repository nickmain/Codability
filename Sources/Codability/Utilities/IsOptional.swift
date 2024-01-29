// Copyright (c) 2024 David N Main

import Foundation

/// Allow "where" clauses to specify that a type is Optional
public protocol IsOptional: ExpressibleByNilLiteral {}
extension Optional: IsOptional {}
