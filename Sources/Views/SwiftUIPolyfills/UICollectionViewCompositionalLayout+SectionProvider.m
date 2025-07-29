#import "UICollectionViewCompositionalLayout+SectionProvider.h"

@implementation UICollectionViewCompositionalLayout (UICollectionViewCompositionalLayout_SectionProvider)
- (UICollectionViewCompositionalLayoutSectionProvider)sectionProvider {
    // Using a private API here, but this code is only ever invoked on iOS 16 which
    // is quite old. Nothing will break here.
    return [self valueForKey:@"_layoutSectionProvider"];
}
@end
