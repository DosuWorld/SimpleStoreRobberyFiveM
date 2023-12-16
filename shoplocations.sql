SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for shoplocations
-- ----------------------------
DROP TABLE IF EXISTS `shoplocations`;
CREATE TABLE `shoplocations`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of shoplocations
-- ----------------------------
INSERT INTO `shoplocations` VALUES (1, 'test', '0');
INSERT INTO `shoplocations` VALUES (2, 'test2', '0');

SET FOREIGN_KEY_CHECKS = 1;
